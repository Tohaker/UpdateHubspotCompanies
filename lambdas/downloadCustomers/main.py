import pysftp
import os, sys
import datetime
import calendar
import boto3
import csv
import logging
import json

username = os.environ['FTP_USERNAME']
password = os.environ['FTP_PASSWORD']
host = os.environ['FTP_URL']
local_file = '/tmp/file.csv'

now = datetime.datetime.now()
dynamodb = boto3.resource('dynamodb', region_name='eu-west-2')
lambda_client = boto3.client('lambda')

if __name__ == 'main':
    logger = logging.getLogger()
    if logger.handlers:
        for handler in logger.handlers:
            logger.removeHandler(handler)
    logging.basicConfig(level=os.environ.get("LOGLEVEL", "INFO"))

def lambda_handler(event, context):
    month = now.month
    month_str = calendar.month_name[month-1]

    file_name = (month_str[:3].upper() + 'V' + str(now.year)[-2:] + '_' + username + '_Services.CSV')
    logger.info('Downloading file: ' + file_name)

    download_file(file_name)
    users = parse_customers_from_file(local_file)
    payload = json.dumps(users)

    max_size = 262144
    if sys.getsizeof(payload) >= max_size:
        items = users.items()
        payload_1 = json.dumps(dict(list(items)[len(users)//2:]))
        payload_2 = json.dumps(dict(list(items)[:len(users)//2]))
        invoke_response_1 = lambda_client.invoke(FunctionName="MatchCustomerIDs",
                                           InvocationType='Event',
                                           Payload=json.dumps(payload_1))
        invoke_response_2 = lambda_client.invoke(FunctionName="MatchCustomerIDs",
                                           InvocationType='Event',
                                           Payload=json.dumps(payload_2))     
        logger.info(invoke_response_1)
        logger.info(invoke_response_2)
        return { 'response_1': invoke_response_1['StatusCode'], 'response_2': invoke_response_2['StatusCode'] }                           
    else:
        invoke_response = lambda_client.invoke(FunctionName="matchCustomerIDs",
                                            InvocationType='Event',
                                            Payload=json.dumps(users))
        logger.info(invoke_response)
        return {'response': invoke_response['StatusCode']}

def download_file(file_name):
    port = 2222

    cnopts = pysftp.CnOpts()
    cnopts.hostkeys = None

    with pysftp.Connection(host, username=username, password=password, port=port, cnopts=cnopts) as sftp:
        with sftp.cd('Monthly/' + str(now.year)):
                sftp.get(file_name, local_file)

def parse_customers_from_file(file_name):
    previous_user = ''
    headers = []
    users = {}
    services = []

    logger.info('Reading File ' + file_name)

    with open(file_name) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')

        for index, row in enumerate(csv_reader):
            if index == 0:
                headers = row
                logger.info('Headers are: %s', ", ".join(row))
            else:
                temp = {}
                for j, item in enumerate(row):
                    temp[headers[j]] = row[j]

                current_user = temp['End User Account']

                if current_user == '':
                    logger.info('No user found on line %s: %s' % (str(index), temp))
                    continue

                if previous_user != current_user:
                    if previous_user != '':
                        users[previous_user] = services
                        services = []
                    previous_user = current_user

                services.append(temp)

    logger.info('Processed %d lines.' % (index + 1))
    logger.info(users)
    return users
