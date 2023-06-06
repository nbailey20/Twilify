import json, os
from google.cloud import pubsub_v1

def send_message(params):
    client = pubsub_v1.PublisherClient()
    data = json.dumps(params).encode()
    response = client.publish(os.environ["tmf_app_topic"], data)
    return response
