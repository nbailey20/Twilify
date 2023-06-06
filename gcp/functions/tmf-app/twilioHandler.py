## Handles Twilio success / error message operations

import os
from urllib.parse import unquote

from twilio.rest import Client


def send_error_message(user_number, message):
    account_sid = os.environ["twilio_account_sid"]
    auth_token = os.environ["twilio_auth_token"]
    try:
        client = Client(account_sid, auth_token)
        client.messages.create(
            body="TMF Error:\n" + message,
            from_=os.environ["twilio_number"],
            to=unquote(user_number)
        )
    except:
        print("ERROR: failed to send error text")
    return



def send_completed_message(user_number, message):
    print("User num", user_number)
    account_sid = os.environ["twilio_account_sid"]
    auth_token = os.environ["twilio_auth_token"]
    try:
        client = Client(account_sid, auth_token)
        client.messages.create(
            body="Done! " + message,
            from_=os.environ["twilio_number"],
            to=unquote(user_number)
        )
    except:
        print("ERROR: failed to send success text")
    return

