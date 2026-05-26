import json
import boto3
import os
import time
import base64
import email
import urllib.parse
import urllib.request

# Configuration
logger = boto3.client('logs') # Standard logging
dynamodb = boto3.resource('dynamodb')
s3_client = boto3.client('s3')

# 🛡️ ASSETS HIDDEN: Loaded via Environment Variables
TABLE_NAME = os.environ.get('DYNAMODB_TABLE', 'FrontPageCity_Intake')
ARTIFACT_BUCKET = os.environ.get('ARTIFACT_BUCKET')
TELEGRAM_BOT_TOKEN = os.environ.get('TELEGRAM_BOT_TOKEN')
TELEGRAM_CHAT_ID = os.environ.get('TELEGRAM_CHAT_ID')

table = dynamodb.Table(TABLE_NAME)

def send_telegram_alert(service, neighborhood, name, email, details, form_data):
    """Secure Telegram Dispatcher."""
    header = f"🚨 NEW {service.upper()} INTAKE 🚨"
    
    def escape_html(text):
        return str(text).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

    message = (
        f"<b>{header}</b>\n"
        f"📍 <b>Region:</b> {escape_html(neighborhood)}\n"
        f"👤 <b>Lead:</b> {escape_html(name)}\n"
        f"📧 <b>Email:</b> {escape_html(email)}\n"
        f"📝 <b>Details:</b> {escape_html(details)}"
    )

    api_url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    params = {
        'chat_id': TELEGRAM_CHAT_ID,
        'parse_mode': 'HTML',
        'text': message
    }
    
    data = urllib.parse.urlencode(params).encode('utf-8')
    req = urllib.request.Request(api_url, data=data)
    with urllib.request.urlopen(req, timeout=10):
        pass

def handler(event, context):
    try:
        # 1. Payload Normalization
        body_bytes = base64.b64decode(event['body']) if event.get("isBase64Encoded") else event.get('body', '').encode('utf-8')
        
        # 2. Extract Data (Simplified for Reliability)
        form_data = urllib.parse.parse_qs(body_bytes.decode('utf-8', errors='ignore'))
        form_data = {k: v[0].strip() for k, v in form_data.items()}

        lead_data = {
            'site_id': form_data.get('site_id', 'frontpagecity-buyers'),
            'lead_id': f"LEAD#{int(time.time())}",
            'name': form_data.get('name', 'Anonymous'),
            'email': form_data.get('email', 'N/A'),
            'details': form_data.get('details', ''),
            'status': 'NEW_LEAD',
            'timestamp': str(int(time.time()))
        }

        # 3. Persistence
        table.put_item(Item=lead_data)
        
        # 4. S3 Archive
        s3_client.put_object(
            Bucket=ARTIFACT_BUCKET,
            Key=f"leads/{lead_data['lead_id']}.json",
            Body=json.dumps(lead_data)
        )

        # 5. Live Dispatch
        send_telegram_alert(
            form_data.get('service', 'general'),
            form_data.get('location', 'unknown'),
            lead_data['name'],
            lead_data['email'],
            lead_data['details'],
            form_data
        )

        return {"statusCode": 302, "headers": {"Location": "https://frontpagecity.com/success-buyer"}}

    except Exception as e:
        print(f"CRITICAL: {str(e)}")
        return {"statusCode": 500, "body": "Processing Failed"}