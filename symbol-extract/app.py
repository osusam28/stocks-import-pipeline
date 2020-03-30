from lib.finnhub import Finnhub
from google.cloud import storage

import json
import os

ENDPONT = '/stock/symbol?exchange=US'

def trigger(event, context):

    print('receiving event ...')

    finn = Finnhub(os.environ['AUTH_KEY'])
    symbols = finn.get(ENDPONT).json()

    client = storage.Client()
    bucket = client.get_bucket(os.environ.get('BUCKET'))
    blob = bucket.get_blob(os.environ.get('FILE_NAME'))

    print('saving data to gs://{}/{} ...'.format(os.environ.get('BUCKET'), os.environ.get('FILE_NAME')))
    blob.upload_from_string(json.dumps(symbols))

