import json
import boto3
from botocore.exceptions import ClientError
from decimal import Decimal

# Initialize the DynamoDB resource outside the handler for connection reuse
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('WebsiteCounter') 

def lambda_handler(event, context):
    # 1. Determine the page identifier
    # You can hardcode this (e.g., 'homepage') or retrieve it from query parameters
    # Example: page_id = event.get('queryStringParameters', {}).get('page', 'default_page')
    page_id = 'homepage' 

    try:
        # 2. Atomic Update
        # This instruction tells DynamoDB to find the item with Key 'page_id'
        # and mathematically add 1 to the 'visit_count' column.
        # If the item doesn't exist, DynamoDB creates it automatically.
        response = table.update_item(
            Key={
                'page_id': page_id
            },
            UpdateExpression='ADD visit_count :increment',
            ExpressionAttributeValues={
                ':increment': 1
            },
            ReturnValues='UPDATED_NEW'
        )

        # 3. Parse the result
        # DynamoDB returns numbers as Decimal types, which JSON cannot serialize by default.
        # We must cast it to an integer.
        current_count = int(response['Attributes']['visit_count'])

        # 4. Return the response (formatted for API Gateway)
        return {
            'statusCode': 200,
            'headers': {
                # Essential for calling this function from a browser (CORS)
                'Access-Control-Allow-Origin': '*', 
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'count': current_count})
            
        }

    except ClientError as e:
        print(f"Error updating DynamoDB: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Unable to update visitor count'})
        }