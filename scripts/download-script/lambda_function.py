import json
import os
import boto3
from botocore.exceptions import ClientError
from datetime import datetime

# Initialize AWS clients
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

# Environment variables (configure these in Lambda settings)
BUCKET_NAME = os.getenv('S3_BUCKET_NAME')
DYNAMO_TABLE_NAME = os.getenv('DYNAMODB_TABLE_NAME')

# Lambda handler
def lambda_handler(event, context):
    # CORS headers to be included in every response
    headers = {
        'Access-Control-Allow-Origin': '*',  # Allow all origins (adjust as needed)
        'Access-Control-Allow-Methods': 'OPTIONS,GET',  # Allow specific methods
        'Access-Control-Allow-Headers': 'Content-Type',  # Allow specific headers
    }

    # Check if this is a preflight (OPTIONS) request
    if event['httpMethod'] == 'OPTIONS':
        return {
            'statusCode': 200,
            'body': '',
            'headers': headers
        }
    
    # Get access_code from the query parameters
    access_code = event['queryStringParameters'].get('access_code')

    if not access_code:
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Access code is required'}),
            'headers': headers  # Include CORS headers in the error response
        }

    # Retrieve the file metadata from DynamoDB
    table = dynamodb.Table(DYNAMO_TABLE_NAME)
    try:
        response = table.get_item(Key={'access_code': access_code})
    except ClientError as e:
        print(f"Error retrieving item from DynamoDB: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error retrieving file metadata'}),
            'headers': headers  # Include CORS headers in the error response
        }

    if 'Item' not in response:
        return {
            'statusCode': 404,
            'body': json.dumps({'message': 'File not found'}),
            'headers': headers  # Include CORS headers in the error response
        }

    file_data = response['Item']
    
    # Check if the file has expired
    expiration_date = file_data['expiration_date']
    expiration_datetime = datetime.fromisoformat(expiration_date)

    if datetime.utcnow() > expiration_datetime:
        return {
            'statusCode': 403,
            'body': json.dumps({'message': 'Access code has expired'}),
            'headers': headers  # Include CORS headers in the error response
        }

    # Generate a presigned URL to download the file from S3
    s3_key = file_data['s3_key']
    try:
        presigned_url = s3_client.generate_presigned_url('get_object',
                                                         Params={'Bucket': BUCKET_NAME, 'Key': s3_key},
                                                         ExpiresIn=3600)  # URL expires in 1 hour
    except ClientError as e:
        print(f"Error generating presigned URL: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error generating presigned URL'}),
            'headers': headers  # Include CORS headers in the error response
        }

    # Return the presigned URL
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Presigned URL generated successfully',
            'download_url': presigned_url
        }),
        'headers': headers  # Include CORS headers in the success response
    }
