import boto3
import os, json
from eventHandler import validate_text_event
import textHandler
from urllib.parse import unquote

## Terraform bools not capitalized unlike Python
DEBUG = True if os.environ["debug"] == "true" else False

    
def lambda_handler(event, _):
    if DEBUG: print("DEBUG: starting TMF reception main function")

    ## validate text event
    source_num = unquote(validate_text_event(event))
    if not source_num:
        return
    if DEBUG: print("DEBUG: validated text event")

    ## parse text event
    playlist_params = textHandler.parse_text(DEBUG, event["Body"])
    choices_captured = "Message received!"
    if len(playlist_params.keys()) > 0:
        choices_captured = " ".join(playlist_params.keys()) + " requests captured"
    
    ## if user requested music, acknowledge and echo back any keywords detected
    if "seeds" not in playlist_params:
        response_body   = "New music update coming right away. \n"
        textHandler.send_acknowledgement_text(DEBUG, source_num, response_body + choices_captured)

    ## launch app with parameters and number to txt back to
    playlist_params["user_number"] = source_num
    try:
        if DEBUG: print("DEBUG: Launching TMF app")
        client = boto3.client("lambda")
        client.invoke(
            FunctionName="tmf",
            InvocationType="Event",
            Payload=json.dumps(playlist_params),
        )
        if DEBUG: print("DEBUG: successfully launched TMF app")
        return
    except:      
        if DEBUG: print("DEBUG: failed to invoke TMF lambda function.")
        return
