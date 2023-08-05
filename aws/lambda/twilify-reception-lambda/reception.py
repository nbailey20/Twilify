import boto3
import os, json
from helpers.incoming_text import parse_event, valid_signature, allowed_source
from helpers.text_keywords import get_text_keywords
from helpers.response_text import send_response_text

## Terraform bools not capitalized unlike Python
DEBUG = True if os.environ["debug"] == "true" else False

    
def lambda_handler(event, _):
    if DEBUG: print("DEBUG: starting Twilify reception main function")

    ## parse text event containing text body and metadata
    text_json = parse_event(event)
    if not text_json:
        if DEBUG: print(f"DEBUG: failed to parse text event: {event}")
        return
    if DEBUG: print("DEBUG: successfully parsed text event")

    ## validate text event is signed by Twilio
    if not valid_signature(text_json):
        if DEBUG: print(f"DEBUG: unable to confirm text event is signed by Twilio")
        return
    if DEBUG: print("DEBUG: successfully validated text event is signed by Twilio")

    ## verify text came from allowed source number
    if not allowed_source(text_json["From"]):
        if DEBUG: print(f"DEBUG: message did not originate from allowed source user")
        return
    if DEBUG: print("DEBUG: successfully verified text is from allowed source number")

    ## grab any user-provided keywords in text
    app_params = get_text_keywords(DEBUG, text_json["Body"])
    choices_captured = "Message received!"
    if len(app_params.keys()) > 0:
        choices_captured = " ".join(app_params.keys()) + " requests captured"

    ## if user requested music, acknowledge and echo back any keywords detected
    if "seeds" not in app_params:
        response_body   = "New music update coming right away. \n"
        send_response_text(DEBUG, text_json["From"], response_body + choices_captured)

    ## launch app with parameters and number to txt back to
    app_params["user_number"] = text_json["From"]
    try:
        if DEBUG: print("DEBUG: Launching Twilify app")
        client = boto3.client("lambda")
        client.invoke(
            FunctionName="twilify",
            InvocationType="Event",
            Payload=json.dumps(app_params),
        )
        if DEBUG: print("DEBUG: successfully launched Twilify app")
        return
    except:      
        if DEBUG: print("DEBUG: failed to invoke Twilify lambda function.")
        return
