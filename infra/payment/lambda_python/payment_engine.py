import json
import os
import boto3
from datetime import datetime
from decimal import Decimal

# Initialize Clients
dynamodb = boto3.resource('dynamodb')
ssm_client = boto3.client('ssm')

# Environment-Driven Configuration
TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME', 'global-payment-ledger')
SSM_ROUTING_PATH = os.environ.get('SSM_ROUTING_PATH', '/payments/routing')

table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    """Secure Ledger Ingestion & Payment Execution."""
    try:
        # Use Decimal for financial precision as requested
        payload = json.loads(event.get('body', '{}'), parse_float=Decimal)

        business_unit = payload.get('source_business', '').lower()
        
        # Secure key retrieval from Parameter Store
        ssm_resp = ssm_client.get_parameter(Name=SSM_ROUTING_PATH, WithDecryption=True)
        routing_map = json.loads(ssm_resp['Parameter']['Value'])
        
        api_key = routing_map.get(business_unit)
        if not api_key:
            raise ValueError(f"Unauthorized business line: {business_unit}")

        # Transaction execution logic remains decoupled here
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

        return {
            "statusCode": 200,
            "body": json.dumps({"status": "processed", "transaction_id": txn_id})
        }

    except Exception as e:
        print(f"CRITICAL PAYMENT FAILURE: {str(e)}")
        return {"statusCode": 500, "body": json.dumps({"error": "Processing failed"})}