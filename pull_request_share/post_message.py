#!/usr/bin/env python

import requests
import json
import sys
import os

# Get all variables from environment

params = dict()

requireds = ['MESSAGE_FILE', 
             'COMMENTS_URL', 
             'AUTH_HEADER', 
             'HEADER', 
             'API_VERSION',
             'GITHUB_TOKEN']

for required in requireds:
    
    value = os.environ.get(required)
    if required == None:
        print('Missing environment variable %s' %required)
        sys.exit(1)

    params[required] = value

custom_message = os.environ.get('CUSTOM_MESSAGE', '')
hashtags = os.environ.get('HASHTAGS', '')
data_url = os.environ.get('DATA_URL', 'https://www.github.com/vsoch/twitter-share')
at_username = os.environ.get('AT_USERNAME', '')

infile = params['MESSAGE_FILE']

if not os.path.exists(infile):
    print('Does not exist: %s' %infile)
    sys.exit(1)
    

with open(infile, 'r') as filey:
    links = filey.read()

print(links)

# Prepare request
accept = "application/vnd.github.%s+json;application/vnd.github.antiope-preview+json" % params['API_VERSION']
headers = {"Authorization": "token %s" % params['GITHUB_TOKEN'],
           "Accept": accept,
           "Content-Type": "application/json; charset=utf-8" }

message = "<a class='twitter-share-button' href=\"https://twitter.com/intent/tweet?text=\"" + custom_message + " " + links + " " + hashtags + "\"&url=\"" + data_url + "\"&related=\""+ at_username + "\">Share on Twitter</a>"

message = message.replace('\n', ' ')

data = {"body": message}
print(data)
print(json.dumps(data).encode('utf-8'))
response = requests.post(params['COMMENTS_URL'],
                         data = json.dumps(data).encode('utf-8'), 
                         headers = headers)
print(response.json())
print(response.status_code)
