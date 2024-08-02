import json
import boto3
import os
from boto3.dynamodb.conditions import Key


# Access environment variables
dynamodb_table_name = os.environ['DYNAMODB_TABLE_NAME']
s3_bucket_name = os.environ['S3_BUCKET_NAME']


dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(dynamodb_table_name)

        
def lambda_handler(event, context):
    # Log the incoming event
    print("Received event: " + json.dumps(event, indent=2))
    
    path = event.get('path', '')
    http_method = event.get('httpMethod' , ' ')
    
    if path == '/resume/list' and http_method == "GET":
        return get_all_resumes()
    
    elif path == '/resume' and http_method == "POST":
        return post_resume(event)
     
    elif path == '/resume/person' and http_method == "GET":
        query_params = event.get('queryStringParameters', {})
        email = query_params.get('email')
        if email:
            return get_resume_by_email(email)
        else:
            return {
                'statusCode': 400,
                'body': json.dumps('Bad Request: Missing parameter "email"')
            }
    else:
        return {
            'statusCode': 404,
            'body': json.dumps('Not Found')
        }

def get_all_resumes ():
    try:
        response = table.scan()
        resumes = response.get('Items', [])
        return {
            'statusCode': 200,
            'body': json.dumps(resumes)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error Fetching Resumes: {str(e)}')
        }
        
def post_resume (event):
    try:
        body = json.loads(event.get('body', ''))
        # validata fields
        required_fields = ['job_applied', 'CV_used', 'email_used', 'date_of_application']
        for field in required_fields:
            if field not in body:
                return {
                'statusCode': 404,
                'body': (f'Missing required Field, {field}')
                }
        
        # Prepare item to insert into DynamoDB
        item = {
            'job_applied': body['job_applied'],
            'CV_used': body['CV_used'],
            'email_used': body['email_used'],
            'date_of_application': body['date_of_application']
            }
        
        # Put item into DynamoDB table
        table.put_item(Item=item)
        return {
            'statusCode': 201,
            'body': json.dumps('Resume added successfully')
            }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error adding resume: {str(e)}')
        }
        

def get_resume_by_email(email):
    try:
        response = table.query(
            IndexName='email_index',  
            KeyConditionExpression=Key('email_used').eq(email)
        )
        items = response.get('Items', [])
        if items:
            return {
                'statusCode': 200,
                'body': json.dumps(items[0])
            }
        else:
            return {
                'statusCode': 404,
                'body': json.dumps('Resume not found')
            }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error Fetching Resume: {str(e)}')
        }