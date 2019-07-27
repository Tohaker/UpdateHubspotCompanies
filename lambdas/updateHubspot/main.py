import os
import logging
import requests
import boto3
import datetime
from decimal import Decimal
from tabulate import tabulate

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

    success = False

    for record in event['Records']:
        logger.info('Stream record: ' + str(record))
        if record['eventName'] == 'MODIFY' or record['eventName'] == 'INSERT':
            value = format_property_value(record['dynamodb']['NewImage']['Services']['L'])
            company = record['dynamodb']['NewImage']['CompanyId']['N']
            if int(company) > 0:
                success = update_property(auth_token, company, service_name, value)

    return {
        'Success': success
    }

def property_exists(auth_token, _property):
    response = requests.get('https://api.hubapi.com/properties/v1/companies/properties/named/' + _property, headers={'Authorization': 'Bearer ' + auth_token})
    response = response.json()
    logger.info('Checking Property (%s) Exists' % _property)
    logger.info(response)
    if 'name' in response:
        return True
    else:
        return False

def group_exists(auth_token, group):
    response = requests.get('https://api.hubapi.com/properties/v1/companies/groups', headers={'Authorization': 'Bearer ' + auth_token})
    logger.info('Checking Group (%s) Exists' % group)
    response = response.json()
    logger.info(response)

    if any(d['name'] == 'daisy' for d in response):
        return True
    else:
        return False

def create_property(auth_token, service_name):
    headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + auth_token
    }
    data = {
        "name": service_name,
        "label": "Daisy Services",
        "description": "List of current services provided by Daisy",
        "groupName": "daisy",
        "type": "string",
        "fieldType": "textarea"
    }
    response = requests.post('https://api.hubapi.com/properties/v1/companies/properties', headers=headers, data=data)
    response = response.json()
    logger.info(response)
    if 'status' in response:
        return False
    else:
        return True

def format_property_value(services):
    _list = ''
    for services in services:
        _list += services['M']['Description']['S'] + ' x ' + services['M']['Quantity']['S'] + '\t\tUnit Cost: ' + services['M']['End User Unit Cost']['S'] + '\n'

    logger.info(_list)
    return _list

def update_property(auth_token, company, _property, value):
    headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + auth_token
    }
    data = {
        "properties": [
            {
                "name": _property,
                "value": value
            }
        ]
    }
    response = requests.put('https://api.hubapi.com/companies/v2/companies/' + company, headers=headers, json=data)
    response = response.json()
    logger.info(response)
    
    if 'portalId' in response:
        return True
    else:
        return False

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
        response = response.json()
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
    expires_at = Decimal(now + expires_in)
    
    # Add the new token set.
    table.put_item(
        Item={
            'access_token': access_token,
            'refresh_token': refresh_token,
            'expires_in': expires_in,
            'expires_at': expires_at
        }
    )