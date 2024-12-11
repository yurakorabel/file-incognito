import json
import os
import uuid
import boto3
import base64
from botocore.exceptions import ClientError
from datetime import datetime, timedelta

# Initialize AWS clients
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
sns_client = boto3.client('sns')

# Environment variables (configure these in Lambda settings)
BUCKET_NAME = os.getenv('S3_BUCKET_NAME')
DYNAMO_TABLE_NAME = os.getenv('DYNAMODB_TABLE_NAME')
SNS_TOPIC_ARN = os.getenv('SNS_TOPIC_ARN')

# Lambda handler
def lambda_handler(event, context):

    # CORS headers to be included in every response
    headers = {
        'Access-Control-Allow-Origin': '*',  # Allow all origins (adjust as needed)
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET',  # Allow specific methods
        'Access-Control-Allow-Headers': 'Content-Type',  # Allow specific headers
    }

    # Check if this is a preflight (OPTIONS) request
    if event['httpMethod'] == 'OPTIONS':
        return {
            'statusCode': 200,
            'body': '',
            'headers': headers
        }

    # Log the event for debugging
    print(f"Received event: {json.dumps(event)}")
    
    # Ensure the body is parsed correctly (it's a string initially)
    try:
        body = json.loads(event['body'])  # Parse the body
    except Exception as e:
        print(f"Error parsing the body: {str(e)}")
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Invalid request format'}),
            'headers': headers  # Include CORS headers in the error response
        }

    # Extract the parameters from the parsed JSON body
    file_content = body.get('file_content')
    file_name = body.get('file_name')
    recipient_email = body.get('recipient_email')

    # Check if all required parameters are provided
    if not file_content or not file_name or not recipient_email:
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Missing required parameters: file_content, file_name, or recipient_email'}),
            'headers': headers  # Include CORS headers in the error response
        }

    # Generate a unique access code
    access_code = str(uuid.uuid4())

    # Upload the file to S3
    s3_key = f"uploads/{access_code}/{file_name}"
    try:
        # Decode the base64-encoded file content
        file_content_bytes = base64.b64decode(file_content)
        s3_client.put_object(
            Bucket=BUCKET_NAME,
            Key=s3_key,
            Body=file_content_bytes  # Store the content as is, it should be base64-decoded if needed
        )
    except ClientError as e:
        print(f"Error uploading file to S3: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error uploading file to S3'}),
            'headers': headers  # Include CORS headers in the error response
        }

    # Record the file metadata in DynamoDB
    expiration_date = (datetime.utcnow() + timedelta(days=7)).isoformat()  # 7-day expiration
    table = dynamodb.Table(DYNAMO_TABLE_NAME)
    try:
        table.put_item(
            Item={
                'access_code': access_code,
                'file_name': file_name,
                's3_key': s3_key,
                'recipient_email': recipient_email,
                'expiration_date': expiration_date
            }
        )
    except ClientError as e:
        print(f"Error writing metadata to DynamoDB: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error saving metadata to DynamoDB'}),
            'headers': headers  # Include CORS headers in the error response
        }

    # Send an email with the access code using SNS
    email_subject = "Your File Access Code"
    email_body = f"Hello,\n\nYou can access your file using the following code: {access_code}.\n\nPlease use the code within 7 days.\n\nThank you!"
    try:
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=email_body,
            Subject=email_subject,
            MessageAttributes={
                'email': {
                    'DataType': 'String',
                    'StringValue': recipient_email
                }
            }
        )
    except ClientError as e:
        print(f"Error sending email via SNS: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error sending email'}),
            'headers': headers  # Include CORS headers in the error response
        }

    # Return a success response
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'File uploaded and email sent successfully',
            'access_code': access_code
        }),
        'headers': headers  # Include CORS headers in the success response
    }
