import pysftp
import os
import logging
import datetime
import calendar
import boto3
import csv

now = datetime.datetime.now()
dynamodb = boto3.resource('dynamodb')

username = os.environ['FTP_USERNAME']
password = os.environ['FTP_PASSWORD']
host = os.environ['FTP_URL']

def lambda_handler(event, context):
    month = datetime.datetime.now().month
    month_str = calendar.month_name[month-1]

    file_name = (month_str[:3].upper() + 'V' + str(now.year)[-2:] + '_' + username + '_Services.CSV')
    logging.info('Downloading file: ' + file_name)

    downloadFile(file_name)
    uploadCustomersToDynamoDB()

def downloadFile(file_name):
    port = 2222

    cnopts = pysftp.CnOpts()
    cnopts.hostkeys = None

    with pysftp.Connection(host, username=username, password=password, port=port, cnopts=cnopts) as sftp:
        with sftp.cd('Monthly'):
            with sftp.cd(str(now.year)):
                sftp.get(file_name, 'file.csv')

def uploadCustomersToDynamoDB():
    table = dynamodb.Table('services')
    users = parseCustomersFromFile('file.csv')
    for user in users:
        table.put_item(
            Item={
                'user_account': user,
                'services': users[user]
            }
        )

def parseCustomersFromFile(file_name):
    line_count = 0
    previous_user = ''
    users = {}
    services = []

    with open(file_name) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')

        for row in csv_reader:
            if line_count == 0:
                line_count += 1
            else:
                user_account = row[13]

                if user_account == '':
                    print('found empty on line ' + str(line_count))
                    continue

                temp = {}
                temp['quantity'] = row[4]
                temp['unit_cost'] = row[5]
                temp['description'] = row[7]

                if previous_user != user_account:
                    if previous_user != '':
                        users[previous_user] = services
                        services = []
                    previous_user = user_account

                services.append(temp)

                line_count += 1

    logging.info(f'Processed {line_count} lines.')
    logging.info(users)
    return users
