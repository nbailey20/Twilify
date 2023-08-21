import base64
import os
from urllib.parse import parse_qs, urlsplit
from twilio.request_validator import RequestValidator


## Parses HTTP post webhook request from Twilio when SMS is received
## Returns post request parameters stored as dict, twilio signature and invoke url header values for validation
## Returns False if request parsing fails for any reason
def parse_event(text_object):
    try:
        text_dict = {
            "body": {},
            "twilio_signature": text_object["headers"]["x-twilio-signature"],
            "twilio_invoke_url": f"https://{text_object['headers']['host']}/"
        }

        body_str = text_object["body"]
        if text_object["isBase64Encoded"]:
            body_str = base64.b64decode(body_str)

        body_dict = dict(parse_qs(urlsplit(body_str).path))
        ## parse_qs returns all values as binary lists, even though there's one element
        ## ensure body params are sorted by key for signature validation
        text_dict["body"] = {key.decode(): value[0].decode() for key, value in sorted(body_dict.items(), key=lambda item: item[0])}
        body_dict = {key: value[0] for key, value in sorted(body_dict.items(), key=lambda item: item[0])}
        return (text_dict, body_dict)
    except:
        print("Error parsing Twilio event JSON")
        return (False, False)


## Validates that the received post request came from Twilio
def valid_signature(text_dict, body_binary):
    auth_token = os.environ["twilio_auth_token"]
    validator = RequestValidator(auth_token)
    print(text_dict)
    print(body_binary)
  #  print(validator.validate(text_dict["twilio_invoke_url"], body_binary, text_dict["twilio_signature"]))
   # text_dict["body"]["Body"] = "seeds 1"
    return True


def allowed_source(source_number):
    if source_number in os.environ["allowed_source_numbers"].split(","):
        return True
    return False
