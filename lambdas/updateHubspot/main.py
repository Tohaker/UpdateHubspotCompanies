import os
import logging
import requests
import boto3

table = boto3.resource('dynamodb').Table('hubspot')

logger = logging.getLogger()
if logger.handlers:
    for handler in logger.handlers:
        logger.removeHandler(handler)
logging.basicConfig(level=os.environ.get("LOGLEVEL", "INFO"))

def lambda_handler(event, context):
    service_name = os.environ['SERVICE_NAME']
    auth_token = get_valid_auth_token()

    for record in event['Records']:
        logger.info('Stream record: ' + record)
        if event['eventName'] == 'MODIFY' or event['eventName'] == 'INSERT':
            response = requests.get('https://api.hubapi.com/properties/v1/companies/properties/named/' + service_name, headers={'Authorization': auth_token})

def get_valid_auth_token():
    table.scan()