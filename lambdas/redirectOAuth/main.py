import os
import urllib.parse

def lambda_handler(event, context):
    authUrl = 'https://app.hubspot.com/oauth/authorize'
    authUrl += '?client_id=' + urllib.parse.quote(os.environ['CLIENT_ID'])
    authUrl += '&scope=contacts'
    authUrl += '&redirect_uri=' + urllib.parse.quote(os.environ['REDIRECT_URI'])

    return {
        'location': authUrl
    }
