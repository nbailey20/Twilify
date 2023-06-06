import os
from urllib.parse import unquote


def compare_event_to_valid(valid_dict, event_dict):
    for valid_property in valid_dict:
        if valid_property not in event_dict:
            return False
        if valid_dict[valid_property] != unquote(event_dict[valid_property]) and unquote(event_dict[valid_property]) not in valid_dict[valid_property]:
            return False
    return True


def test_valid_sms_event(event):
    valid_sms = {
        "SmsStatus": "received",
        "From":      os.environ["user_numbers"].split(","),
        "To":        os.environ["twilio_number"],
        "ToCountry": "US"
    }
    ## compare received event against valid sms fields 
    return compare_event_to_valid(valid_sms, event)


def validate_request(request):
    ## handle SMS events
    if "SmsSid" in request and test_valid_sms_event(request):
        return request["From"]
    return False