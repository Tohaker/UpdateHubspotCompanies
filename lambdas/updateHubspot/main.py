import os
import logging
import requests
import boto3
import datetime

table = boto3.resource('dynamodb').Table('hubspot')

logger = logging.getLogger()
if logger.handlers:
    for handler in logger.handlers:
        logger.removeHandler(handler)
logging.basicConfig(level=os.environ.get("LOGLEVEL", "INFO"))

def lambda_handler(event, context):
    service_name = os.environ['SERVICE_NAME']
    auth_token = get_valid_auth_token()

    if not property_exists(auth_token, service_name):
        create_property(auth_token, service_name)

    for record in event['Records']:
        logger.info('Stream record: ' + record)
        if event['eventName'] == 'MODIFY' or event['eventName'] == 'INSERT':
            

def property_exists(auth_token, property):
    response = requests.get('https://api.hubapi.com/properties/v1/companies/properties/named/' + property, headers={'Authorization': auth_token})
    logger.info('Checking Property (%s) Exists' % property)
    logger.info(response)
    if response['name']:
        return True
    else:
        return False

def group_exists(auth_token, group):
    response = requests.get('https://api.hubapi.com/properties/v1/companies/groups', headers={'Authorization': auth_token})
    logger.info('Checking Group (%s) Exists' % group)
    logger.info(response)

    if any(d['name'] == 'daisy' for d in response):
        return True
    else:
        return False

def create_property(auth_token, property):
    headers = {
        'Content-Type': 'application/json',
        'Authorization': auth_token
    }
    data = {
        "name": os.environ['SERVICE_NAME'],
        "label": "Daisy Services",
        "description": "List of current services provided by Daisy",
        "groupName": "daisy",
        "type": "string",
        "fieldType": "textarea"
    }
    response = requests.post('https://api.hubapi.com/properties/v1/companies/properties', headers=headers, data=data)
    logger.info(response)
    if response['status']:
        return False
    else:
        return True

def update_property(auth_token, company, property, value):
    

def get_valid_auth_token():
    token = table.scan()['Items'][0]

    if token['expires_at'] > datetime.datetime.now().timestamp():
        return token['access_token']
    else:
        refresh_token = token['refresh_token']
        headers = {
            'Content-Type': 'application/x-www-form-urlencoded'
        }
        data = {
            'grant_type': 'refresh_token',
            'client_id': os.environ['CLIENT_ID'],
            'client_secret': os.environ['CLIENT_SECRET'],
            'refresh_token': refresh_token
        }
        response = requests.post('https://api.hubapi.com/oauth/v1/token', data=data, headers=headers)
        save_tokens(response)
        return response['access_token']

def save_tokens(event):
    access_token = event['access_token']
    refresh_token = event['refresh_token']
    expires_in = event['expires_in']

    # Remove all previous tokens.
    if table.item_count > 0:
        response = table.scan()
        for item in response['Items']:
            table.delete_item(
                Key={
                    'access_token': item['access_token']
                }
            )

    now = datetime.datetime.now().timestamp()
    expires_at = now + expires_in
    
    # Add the new token set.
    table.put_item(
        Item={
            'access_token': access_token,
            'refresh_token': refresh_token,
            'expires_in': expires_in,
            'expires_at': expires_at
        }
    )