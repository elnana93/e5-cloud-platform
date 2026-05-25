import json
import boto3
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('DYNAMODB_TABLE_NAME', 'AssetTable'))

def handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        logger.info(f"Updating Asset: {body.get('asset_id')}")

        table.put_item(Item=body)

        return {
            'statusCode': 200,
            'body': json.dumps({'status': 'updated', 'asset': body.get('asset_id')})
        }
    except Exception as e:
        logger.error(f"Asset Management Error: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps({'error': 'Update failed'})}