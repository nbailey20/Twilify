import base64
import os
from urllib.parse import parse_qs, urlsplit

def parse_event(text_object):
    print(text_object)
    try:
        body_str = text_object["body"]
        if text_object["isBase64Encoded"]:
            body_str = base64.b64decode(body_str)

        body_dict = dict(parse_qs(urlsplit(body_str).path))
        ## parse_qs returns all values as binary lists, even though there's one element
        return {key.decode(): value[0].decode() for key, value in body_dict.items()}
    except:
        print('Error parsing Twilio event JSON')
        return False


def valid_signature(text_object):
    return True


def allowed_source(source_number):
    if source_number in os.environ["allowed_source_numbers"].split(","):
        return True
    return False
