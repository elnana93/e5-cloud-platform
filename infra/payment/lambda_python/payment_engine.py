import json
import os
import boto3
import logging
from datetime import datetime
from decimal import Decimal

# Configure Logging for Auditability
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS Clients
dynamodb = boto3.resource('dynamodb')
ssm_client = boto3.client('ssm')

# Constants from Infrastructure Environment Variables
TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')
SSM_ROUTING_PATH = os.environ.get('SSM_ROUTING_PATH')

table = dynamodb.Table(TABLE_NAME)

def validate_payload(payload):
    """Ensure the transaction has all required financial fields."""
    required = ['source_business', 'amount', 'source_domain', 'intake_id']
    for field in required:
        if field not in payload:
            raise ValueError(f"Missing required financial field: {field}")

def handler(event, context):
    """Secure Ledger Ingestion & Payment Execution."""
    try:
        # Use Decimal for financial precision
        payload = json.loads(event.get('body', '{}'), parse_float=Decimal)
        validate_payload(payload)

        business_unit = payload.get('source_business', '').lower()
        
        # Secure key retrieval from Parameter Store
        ssm_resp = ssm_client.get_parameter(Name=SSM_ROUTING_PATH, WithDecryption=True)
        routing_map = json.loads(ssm_resp['Parameter']['Value'])
        
        api_key = routing_map.get(business_unit)
        if not api_key:
            logger.error(f"Unauthorized business unit attempt: {business_unit}")
            raise ValueError("Unauthorized business unit")

        # Transaction Identity
        txn_id = f"TXN_{int(datetime.utcnow().timestamp())}"
        
        # Ledger Entry
        table.put_item(
            Item={
                'PK': f"TXN#{txn_id}",
                'Business': business_unit.upper(),
                'Amount': payload.get('amount'),
                'SourceDomain': payload.get('source_domain'),
                'IntakeID': payload.get('intake_id'),
                'Status': "SUCCESS",
                'Timestamp': datetime.utcnow().isoformat()
            }
        )

        logger.info(f"Transaction processed: {txn_id} for {business_unit}")

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "status": "processed", 
                "transaction_id": txn_id
            })
        }

    except ValueError as ve:
        return {"statusCode": 400, "body": json.dumps({"error": str(ve)})}
    except Exception as e:
        logger.error(f"CRITICAL PAYMENT FAILURE: {str(e)}")
        return {"statusCode": 500, "body": json.dumps({"error": "Processing failed"})}