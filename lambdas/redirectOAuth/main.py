import os
import urllib.parse
import boto3
import logging
import requests

logger = logging.getLogger()
if logger.handlers:
    for handler in logger.handlers:
        logger.removeHandler(handler)
logging.basicConfig(level=os.environ.get("LOGLEVEL", "INFO"))

dynamodb = boto3.resource('dynamodb', region_name='eu-west-2')

def lambda_handler(event, context):
    logger.info(event)

    path = event['path']
    redirectUrl = ''
    bodyHTML = ''
    contentType = 'application/json'
    httpStatusCode = 204

    if path == '/redirect':
        redirectUrl = 'https://app.hubspot.com/oauth/authorize'
        redirectUrl += '?client_id=' + os.environ['CLIENT_ID']
        redirectUrl += '&scope=contacts'
        redirectUrl += '&redirect_uri=' + os.environ['REDIRECT_URI']
        logger.info("Redirecting to " + redirectUrl)
        httpStatusCode = 302
    elif path == '/confirm':
        bodyHTML = get_success_html()
        httpStatusCode = 200
        contentType = 'text/html'

        if not event['queryStringParameters']:
            bodyHTML = get_error_html()
        else:
            code = event['queryStringParameters']['code']
            logger.info('Code Received: ' + code)
            get_access_token(code)
            

    return {
        "statusCode": httpStatusCode, 
        "headers": {
            "content-type": contentType,
            "location": redirectUrl
        },
        "body": bodyHTML
    }

def get_access_token(code):
    auth_url = ('https://api.hubapi.com/oauth/v1/token')
    data = {
        'grant_type': 'authorization_code',
        'client_id' : os.environ['CLIENT_ID'],
        'client_secret': os.environ['CLIENT_SECRET'],
        'redirect_uri': os.environ['REDIRECT_URI'],
        'code': code,
        'headers': {
            'content-type': 'application/x-www-form-urlencoded'
        }
    }
    response = requests.post(auth_url, data)
    logger.info(response.json())
    save_tokens(response.json())

def save_tokens(event):
    access_token = event['access_token']
    refresh_token = event['refresh_token']
    expires_in = event['expires_in']

    table = dynamodb.Table('hubspot')

    # Remove all previous tokens.
    if table.item_count > 0:
        response = table.scan()
        for item in response['Items']:
            table.delete_item(
                Key={
                    'access_token': item['access_token']
                }
            )

    # Add the new token set.
    table.put_item(
        Item={
            'access_token': access_token,
            'refresh_token': refresh_token,
            'expires_in': expires_in
        }
    )

def get_success_html():
    html = """\
    <html>
        <title>LTC Labs</title>
        <body>
            <h1>
                Authorization Succeeded.
            </h1>
            <p>
                You have successfully authorized the Hubspot app.<br>
                You may now close this window.
            </p>
        </body>
    </html>
    """
    return html

def get_error_html():
    html = """\
    <html>
        <title>LTC Labs</title>
        <body>
            <h1>
                Authorization Failed.
            </h1>
            <p>
                Something went wrong, please contact your system administrator.<br>
            </p>
        </body>
    </html>
    """
    return html
