import pysftp
import os
import datetime
import calendar
import boto3
import csv
import logging
import requests
import urllib
from decimal import Decimal

username = os.environ['FTP_USERNAME']
password = os.environ['FTP_PASSWORD']
host = os.environ['FTP_URL']

now = datetime.datetime.now()
dynamodb = boto3.resource('dynamodb', region_name='eu-west-2')

logger = logging.getLogger()
if logger.handlers:
    for handler in logger.handlers:
        logger.removeHandler(handler)
logging.basicConfig(level=os.environ.get("LOGLEVEL", "INFO"))

local_file = '/tmp/file.csv'

def lambda_handler(event, context):
    month = datetime.datetime.now().month
    month_str = calendar.month_name[month-1]

    file_name = (month_str[:3].upper() + 'V' + str(now.year)[-2:] + '_' + username + '_Services.CSV')
    logger.info('Downloading file: ' + file_name)

    downloadFile(file_name)
    uploadCustomersToDynamoDB()

def downloadFile(file_name):
    port = 2222

    cnopts = pysftp.CnOpts()
    cnopts.hostkeys = None

    with pysftp.Connection(host, username=username, password=password, port=port, cnopts=cnopts) as sftp:
        with sftp.cd('Monthly/' + str(now.year)):
                sftp.get(file_name, local_file)

def uploadCustomersToDynamoDB():
    table = dynamodb.Table('customers')
    users = parseCustomersFromFile(local_file)
    customers = getCustomerIDs()

    for user in users:
        id = 0

        for c in customers:
            if c['UserId'] == user:
                id = c['CompanyId']

        table.put_item(
            Item={
                'UserId': user,
                'Services': users[user],
                'CompanyId': id
            }
        )

def parseCustomersFromFile(file_name):
    line_count = 0
    previous_user = ''
    users = {}
    services = []

    logger.info('Reading File ' + file_name)

    with open(file_name) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')

        for row in csv_reader:
            if line_count == 0:
                logger.info('Headers are: %s', ", ".join(row))
                line_count += 1
            else:
                user_account = row[13]
                temp = {}
                temp['quantity'] = row[4]
                temp['unit_cost'] = row[5]
                temp['description'] = row[7]

                if user_account == '':
                    logger.info('Found no user on line %s: %s' % (str(line_count), temp))
                    continue

                if previous_user != user_account:
                    if previous_user != '':
                        users[previous_user] = services
                        services = []
                    previous_user = user_account

                services.append(temp)

                line_count += 1

    logger.info('Processed %d lines.' % line_count)
    logger.debug(users)
    return users

def getCustomerIDs():
    max_results = 500 
    limit = 5 
    company_list = []
    parameters = {
        'limit': limit,
        'properties': 'daisy_id'
    }
    get_all_companies_url = "https://api.hubapi.com/companies/v2/companies/paged?"
    headers = {
        'Authorization': get_valid_auth_token()
    }

    logger.info('Listing Companies.')

    # Paginate the request using offset
    has_more = True
    while has_more:
        params = urllib.parse.urlencode(parameters)
        get_url = get_all_companies_url + params
        response = requests.get(url=get_url, headers=headers)
        
        logger.info(response.json())
        has_more = response.json()['has-more']

        for company in response.json()['companies']:
            map = {
                'CompanyId': company['companyId'],
                'UserId': company['properties']['daisy_id']['value']
            }
            company_list.append(map)

        parameters['offset'] = response.json()['offset']

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
        return 'Bearer ' + token['access_token']
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
        logger.info(response.json())
        save_tokens(response.json())
        return 'Bearer ' + response.json()['access_token']

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
