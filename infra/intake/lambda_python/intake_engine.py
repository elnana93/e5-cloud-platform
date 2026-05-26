import json
import os
import boto3
import time
import base64
import urllib.parse
import urllib.request
import logging

# Setup Logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize Clients
dynamodb = boto3.resource('dynamodb')
s3_client = boto3.client('s3')

# Configuration
TABLE_NAME = os.environ.get('DYNAMODB_TABLE')
ARTIFACT_BUCKET = os.environ.get('ARTIFACT_BUCKET')
TELEGRAM_BOT_TOKEN = os.environ.get('TELEGRAM_BOT_TOKEN')
TELEGRAM_CHAT_ID = os.environ.get('TELEGRAM_CHAT_ID')

table = dynamodb.Table(TABLE_NAME)

def send_telegram_alert(service, name, email, details):
    """Dispatch alert via Telegram Bot."""
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        return # Silent fail if telegram not configured

    message = f"🚨 NEW INTAKE: {service.upper()}\n👤 {name}\n📧 {email}\n📝 {details}"
    api_url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    params = {'chat_id': TELEGRAM_CHAT_ID, 'text': message}
    
    try:
        data = urllib.parse.urlencode(params).encode('utf-8')
        with urllib.request.urlopen(urllib.request.Request(api_url, data=data), timeout=5):
            pass
    except Exception as e:
        logger.error(f"Telegram Dispatch Failed: {str(e)}")

def lambda_handler(event, context):
    """Process incoming lead and persist to storage."""
    try:
        # Decode and Parse
        body = base64.b64decode(event.get('body', '')) if event.get("isBase64Encoded") else event.get('body', '')
        form_data = {k: v[0] for k, v in urllib.parse.parse_qs(body).items()}

        # Map to DynamoDB Schema (site_id + lead_id)
        lead_id = f"LEAD#{int(time.time())}"
        lead_item = {
            'site_id': form_data.get('site_id', 'frontpagecity-default'),
            'lead_id': lead_id,
            'name': form_data.get('name', 'Anonymous'),
            'email': form_data.get('email', 'N/A'),
            'details': form_data.get('details', ''),
            'timestamp': str(int(time.time()))
        }

        # 1. DynamoDB Persistence
        table.put_item(Item=lead_item)
        
        # 2. S3 Artifact Archival
        s3_client.put_object(
            Bucket=ARTIFACT_BUCKET,
            Key=f"leads/{lead_id}.json",
            Body=json.dumps(lead_item)
        )

        # 3. Alerting
        send_telegram_alert(form_data.get('service', 'general'), lead_item['name'], lead_item['email'], lead_item['details'])

        return {"statusCode": 302, "headers": {"Location": "https://frontpagecity.com/success-buyer"}}

    except Exception as e:
        logger.error(f"CRITICAL INTAKE FAILURE: {str(e)}")
        return {"statusCode": 500, "body": json.dumps({"error": "Internal Server Error"})}