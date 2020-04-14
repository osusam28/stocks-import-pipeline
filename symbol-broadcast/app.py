from google.cloud import storage
from google.cloud import pubsub_v1
from flask import Flask, request

import base64
import os
import sys
import json
import time

app = Flask(__name__)
publisher = pubsub_v1.PublisherClient()

LOCAL_FILE_NAME='temp.json'

#
# Get project topics with the label component:symbol-function
#
def get_topics():
    project_path = publisher.project_path(os.environ['PROJECT_ID'])
    print('retrieving topics for {}'.format(project_path))

    topics = []
    for topic in publisher.list_topics(project_path):
        component = topic.labels.get('component')
        if component and component == 'symbol-function':
            topics.append(topic)
    
    return topics

#
# Push messages with the specific symbol to each pubsub topic at an interval
#
def push_symbol(symbol: str, seconds_to_sleep=1):
    topics = get_topics()
    for topic in topics:
        print('publishing symbol to topic [{}]: [{}]'.format(topic.name, symbol))
        time.sleep(seconds_to_sleep)
        publisher.publish(topic.name, data=symbol.encode('utf-8'))

#
# Download and read in file from GCS
#
def get_file(bucket, file_name, local_file_name=LOCAL_FILE_NAME):
    print('downloading file from gs://{}/{} to {}'.format(bucket, file_name, local_file_name))
    client = storage.Client()
    bucket = client.bucket(bucket)
    blob = bucket.blob(file_name)
    blob.download_to_filename(local_file_name)

    return local_file_name

def get_symbols(local_file_name=LOCAL_FILE_NAME):
    print('reading symbols from file {}'.format(local_file_name))
    symbols = []

    with open(local_file_name, 'r') as sf:
        data = json.loads(sf)
        for o in data:
            symbols.append(o.get('displaySymbol'))
    
    return symbols


#
# Entry point
#
@app.route('/', methods=['POST'])
def index():
    envelope = request.get_json()
    if not envelope:
        msg = 'no Pub/Sub message received'
        print(f'error: {msg}')
        return f'Bad Request: {msg}', 400

    if not isinstance(envelope, dict) or 'message' not in envelope:
        msg = 'invalid Pub/Sub message format'
        print(f'error: {msg}')
        return f'Bad Request: {msg}', 400

    pubsub_message = envelope['message']

    if isinstance(pubsub_message, dict) and 'data' in pubsub_message:
        gcs_data = base64.b64decode(pubsub_message['data']).decode('utf-8').strip()

        gcs_data_dict = json.loads(gcs_data)
        bucket = gcs_data_dict.get('bucket')
        file_name = gcs_data_dict.get('name')
        get_file(bucket=bucket, file_name=file_name)
        symbols = get_symbols()

        for symbol in symbols:
            push_symbol(symbol=symbol)
        

    # Flush the stdout to avoid log buffering.
    sys.stdout.flush()

    return ('', 204)