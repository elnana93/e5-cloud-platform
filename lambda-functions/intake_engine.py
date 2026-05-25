import json
import boto3
import logging
import os

# Configure Logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize Resources
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('DYNAMODB_TABLE_NAME', 'IntakeTable'))

def handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        logger.info(f"Received Intake Request: {body.get('id', 'N/A')}")

        # Atomic Insert
        table.put_item(Item=body)

        return {
            'statusCode': 201,
            'body': json.dumps({'status': 'success', 'message': 'Intake recorded'})
        }
    except Exception as e:
        logger.error(f"Intake Error: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps({'error': 'Processing failed'})}