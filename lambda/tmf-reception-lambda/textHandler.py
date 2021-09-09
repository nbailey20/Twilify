import re, os
from twilio.rest import Client



def parse_text(DEBUG, body):
    ## convert body to all lowercase first
    body = body.lower()

    if DEBUG: print("DEBUG: received message " + str(body))
    playlist_params = {}

    ## check to see if reset keyword included in text
    match = re.search(r"keep", body)
    if match is not None:
        if DEBUG: print("DEBUG: found keep keyword")
        playlist_params["keep"] = True

    ## check to see if size keyword included in text
    match = re.search(r"size\+[0-9]+", body)
    if match is not None:
        if DEBUG: print("DEBUG: found size keyword", match.group())
        playlist_params["size"] = int(match.group().split("+")[1])

    ## check to see if happy keyword included in text
    match = re.search(r"happy", body)
    if match is not None and "sad" not in playlist_params:
        if DEBUG: print("DEBUG: found happy keyword")
        playlist_params["happy"] = True

    ## check to see if sad keyword included in text
    match = re.search(r"sad", body)
    if match is not None and "happy" not in playlist_params:
        if DEBUG: print("DEBUG: found sad keyword")
        playlist_params["sad"] = True
    
    ## check to see if tempo keyword included in text
    match = re.search(r"tempo\+[0-9]+", body)
    if match is not None:
        if DEBUG: print("DEBUG: found tempo keyword", match.group())
        playlist_params["tempo"] = int(match.group().split("+")[1])
    
    ## check to see if instrumental keyword included in text
    match = re.search(r"instrumental", body)
    if match is not None:
        if DEBUG: print("DEBUG: found instrumental keyword")
        playlist_params["instrumental"] = True
    
    ## check to see if size keyword included in text
    match = re.search(r"energy\+\w+", body)
    if match is not None:
        if DEBUG: print("DEBUG: found energy keyword", match.group())
        energy_type = match.group().split("+")[1]
        if energy_type == "low":
            playlist_params["energy"] = "low"
        elif energy_type == "medium":
            playlist_params["energy"] = "medium"
        elif energy_type == "high":
            playlist_params["energy"] = "high"
        elif DEBUG: print("DEBUG: did not include valid energy type, ignoring")

    ## check to see if instrumental keyword included in text
    match = re.search(r"dance", body)
    if match is not None:
        if DEBUG: print("DEBUG: found dance keyword")
        playlist_params["dance"] = True

    ## check to see if overwrite keyword included in text
    match = re.search(r"overwrite", body)
    if match is not None:
        if DEBUG: print("DEBUG: found overwrite keyword")
        playlist_params["overwrite"] = True

    ## check to see if seeds keyword included in text
    match = re.search(r"seeds\+[0-9]+", body)
    if match is not None:
        if DEBUG: print("DEBUG: found seeds keyword", match.group())
        playlist_params["seeds"] = int(match.group().split("+")[1])

    
    return playlist_params



def send_acknowledgement_text(DEBUG, user_number, response):
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