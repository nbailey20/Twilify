## Handles Twilio success / error message operations

from twilio.rest import Client
import os


def send_error_message(message):
    account_sid = os.environ["twilio_account_sid"]
    auth_token = os.environ["twilio_auth_token"]
    try:
        client = Client(account_sid, auth_token)
        client.messages.create(
            body="TMF Error:\n" + message,
            from_=os.environ["twilio_number"],
            to=os.environ["user_number"]
        )
    except:
        print("ERROR: failed to send error text")
    return



def send_completed_message(message):
    account_sid = os.environ["twilio_account_sid"]
    auth_token = os.environ["twilio_auth_token"]
    try:
        client = Client(account_sid, auth_token)
        client.messages.create(
            body="TMF Song Generation Complete!:\n" + message,
            from_=os.environ["twilio_number"],
            to=os.environ["user_number"]
        )
    except:
        print("ERROR: failed to send success text")
    return

