import os
import logging
import requests

from retry import retry

BASE_URL='https://finnhub.io/api/v1'

class Finnhub:

    def __init__(self, auth_key, logging_level=logging.INFO):
        logging.basicConfig()
        self.logger = logging.getLogger()
        self.logger.setLevel(logging_level)
        self.auth_key = auth_key
    
    @retry(Exception, tries=5, delay=1)
    def get(self, endpoint: str):
        if endpoint.find('?') > -1:
            endpoint = endpoint + '&'
        else:
            endpoint = endpoint + '?'

        return requests.get(BASE_URL + '{}token={}'.format(endpoint, self.auth_key))