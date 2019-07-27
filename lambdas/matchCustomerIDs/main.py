import urllib
import requests
import logging
import os
import boto3
import datetime
from decimal import Decimal

now = datetime.datetime.now()
dynamodb = boto3.resource('dynamodb', region_name='eu-west-2')

logger = logging.getLogger()
if logger.handlers:
    for handler in logger.handlers:
        logger.removeHandler(handler)
logging.basicConfig(level=os.environ.get("LOGLEVEL", "INFO"))

def lambda_handler(event, context):
    logger.info(event)
    upload_customers_to_dynamodb(event)

def upload_customers_to_dynamodb(event):
    table = dynamodb.Table('customers')
    customers = get_customer_ids()

    for user in event:
        services = []
        for service in event[user]:
            services.append({key: value for key, value in service.items() if value})

        id = 0
        logger.info(user)
        logger.info(services)

        for c in customers:
            if c['UserId'] == user:
                id = c['CompanyId']

        table.put_item(
            Item={
                'UserId': user,
                'Services': services,
                'CompanyId': id
            }
        )    

def get_customer_ids():
    max_results = 500 
    limit = 5 
    company_list = []

    parameters = {
        'limit': limit,
        'properties': 'daisy_id'
    }
    get_all_companies_url = "https://api.hubapi.com/companies/v2/companies/paged?"
    headers = {
        'Authorization': 'Bearer ' + get_valid_auth_token()
    }

    logger.info('Listing Companies.')

    # Paginate the request using offset
    has_more = True
    while has_more:
        params = urllib.parse.urlencode(parameters)
        get_url = get_all_companies_url + params
        response = requests.get(url=get_url, headers=headers)
        response = response.json()

        logger.info(response)
        has_more = response['has-more']

        for company in response['companies']:
            map = {
                'CompanyId': company['companyId'],
                'UserId': company['properties']['daisy_id']['value']
            }
            company_list.append(map)

        parameters['offset'] = response['offset']

        if len(company_list) >= max_results: # Exit pagination, based on whatever value you've set your max results variable to.
            logger.info('Maximum number of results exceeded')
            break

    list_length = len(company_list) 
    logger.info("Succesfully parsed through {} company records and added them to a list".format(list_length))
    logger.info(company_list)

    return company_list

def get_valid_auth_token():
    table = dynamodb.Table('hubspot')
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
        logger.info(response)
        save_tokens(response)
        return response['access_token']

def save_tokens(event):
    table = dynamodb.Table('hubspot')

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