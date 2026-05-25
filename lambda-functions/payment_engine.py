import json
import boto3
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('DYNAMODB_TABLE_NAME', 'PaymentTable'))

def handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        logger.info(f"Processing Payment for Transaction: {body.get('tx_id')}")

        table.put_item(Item=body)

        return {
            'statusCode': 200,
            'body': json.dumps({'status': 'paid', 'tx_id': body.get('tx_id')})
        }
    except Exception as e:
        logger.error(f"Payment Error: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps({'error': 'Transaction failed'})}