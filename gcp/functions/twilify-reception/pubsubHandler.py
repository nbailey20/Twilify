import json, os
from google.cloud import pubsub_v1

## Publish message to PubSub topic that triggers Twilify app function
def launch_app(params):
    try:
        client = pubsub_v1.PublisherClient()
        data = json.dumps(params).encode()
        response = client.publish(os.environ["twilify_app_topic"], data)
        return response
    except Exception as e:
        return f"Failed to publish message to Twilify app topic and launch app: {e}"
