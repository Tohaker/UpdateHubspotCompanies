import pysftp
import os
import datetime
import calendar
import boto3
import csv
import importlib
import logging

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
    for user in users:
        table.put_item(
            Item={
                'UserId': user,
                'Services': users[user]
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

def lambda_handler(event, context):
    month = datetime.datetime.now().month
    month_str = calendar.month_name[month-1]

    file_name = (month_str[:3].upper() + 'V' + str(now.year)[-2:] + '_' + username + '_Services.CSV')
    logger.info('Downloading file: ' + file_name)

    downloadFile(file_name)
    uploadCustomersToDynamoDB()
