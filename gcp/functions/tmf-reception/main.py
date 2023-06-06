import os
from urllib.parse import unquote

from requestHandler import validate_request
import textHandler
from pubsubHandler import send_message


## Terraform bools not capitalized unlike Python
DEBUG = True if os.environ["debug"] == "true" else False


## https://flask.palletsprojects.com/en/1.1.x/api/#incoming-request-data
def main(request):
    if DEBUG: print("DEBUG: starting TMF reception main function")

    ## validate text event
    source_num = unquote(validate_request(request.form))
    if not source_num:
        return
    if DEBUG: print("DEBUG: validated text event")

    ## parse text event
    playlist_params = textHandler.parse_text(DEBUG, request.form["Body"])
    choices_captured = "Message received!"
    if len(playlist_params.keys()) > 0:
        choices_captured = " ".join(playlist_params.keys()) + " requests captured"
    
    ## if user requested music, acknowledge and echo back any keywords detected
    if "seeds" not in playlist_params:
        response_body   = "New music update coming right away. \n"
        textHandler.send_acknowledgement_text(DEBUG, source_num, response_body + choices_captured)

    ## launch app with parameters and number to txt back to
    playlist_params["user_number"] = source_num
    if DEBUG: print("DEBUG: Launching TMF app")
    message_response = send_message(playlist_params)

    if DEBUG: print(f"DEBUG: {message_response}")
    return {
        "status": "200",
        "body": "success"
    }
    # except:      
    #     if DEBUG: print("DEBUG: failed to invoke TMF app function.")
    #     return
