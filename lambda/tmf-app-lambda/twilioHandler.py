from twilio.rest import Client
import os


def send_error_message(message):
    account_sid = os.environ["twilio_account_sid"]
    auth_token = os.environ["twilio_auth_token"]
    client = Client(account_sid, auth_token)

    client.messages.create(
          body="TMF Error:\n" + message,
          from_=os.environ["twilio_number"],
          to=os.environ["user_number"]
          )
    return



def send_completed_message():
    account_sid = os.environ["twilio_account_sid"]
    auth_token = os.environ["twilio_auth_token"]
    client = Client(account_sid, auth_token)

    client.messages.create(
        body="TMF Song Generation Complete!:\nEnjoy your new songs :)",
        from_=os.environ["twilio_number"],
        to=os.environ["user_number"]
    )
    return

