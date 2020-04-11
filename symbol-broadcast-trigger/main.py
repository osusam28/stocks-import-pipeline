from google.cloud import pubsub_v1

import os

def hello_gcs_generic(data, context):

    print('Event ID: {}'.format(context.event_id))
    print('Event type: {}'.format(context.event_type))
    print('Bucket: {}'.format(data['bucket']))
    print('File: {}'.format(data['name']))
    print('Created: {}'.format(data['timeCreated']))

    file_path = data['name']

    if (file_path.find(os.environ['FILE_NAME']) > -1):
        publisher = pubsub_v1.PublisherClient()
        project_id = os.environ['PROJECT_ID']
        topic_name = os.environ['PUBSUB_TOPIC_NAME']

        topic_path = publisher.topic_path(project_id, topic_name)
        message = 'gs://{}/{}'.format(data['bucket'], data['name'])

        print('publishing message {} ...'.format(message))

        publisher.publish(
            topic_path, data=message.encode('utf-8')  # data must be a bytestring
        ).result()

        print('message published')