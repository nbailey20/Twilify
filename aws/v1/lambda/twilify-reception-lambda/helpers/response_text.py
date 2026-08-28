import os
from twilio.rest import Client

def send_response_text(DEBUG, user_number, response):
    account_sid = os.environ["twilio_account_sid"]
    auth_token = os.environ["twilio_auth_token"]
    try:
        client = Client(account_sid, auth_token)
        client.messages.create(
            body = response,
            from_= os.environ["twilio_number"],
            to   = user_number
        )
        if DEBUG: print("DEBUG: successfully sent acknowledgement text")
    except:
        if DEBUG: print("DEBUG: failed to send error text")
    return