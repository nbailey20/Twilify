import re, os
from twilio.rest import Client


def parse_text(DEBUG, body):
    ## convert body to all lowercase first


    if DEBUG: print("DEBUG: received message " + str(body))
    playlist_params = {}

    ## check to see if reset keyword included in text
    match = re.search(r"reset", body)
    if match is not None:
        if DEBUG: print("DEBUG: found reset keyword")
        playlist_params["reset"] = True

    ## check to see if size keyword included in text
    match = re.search(r"size\+[0-9]+", body)
    if match is not None:
        if DEBUG: print("DEBUG: found size keyword", match.group())
        playlist_params["size"] = int(match.group().split("+")[1])

    ## check to see if keyword keyword included in text
    match = re.search(r"keyword\+\w+", body)
    if match is not None:
        if DEBUG: print("DEBUG: found keyword keyword", match.group())
        playlist_params["keyword"] = match.group().split("+")[1]
    
    return playlist_params



def send_acknowledgement_text(DEBUG, response):
    account_sid = os.environ["twilio_account_sid"]
    auth_token = os.environ["twilio_auth_token"]
    try:
        client = Client(account_sid, auth_token)
        client.messages.create(
            body = response,
            from_= os.environ["twilio_number"],
            to   = os.environ["user_number"]
        )
        if DEBUG: print("DEBUG: successfully sent acknowledgement text")
    except:
        if DEBUG: print("DEBUG: failed to send error text")
    return