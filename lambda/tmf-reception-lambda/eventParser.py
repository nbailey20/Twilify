import json, os
from urllib.parse import unquote


def compare_event_to_valid(valid_dict, event_dict):
    for valid_property in valid_dict:
        if valid_property not in event_dict:
            return False
        if valid_dict[valid_property] != unquote(event_dict[valid_property]):
            return False
    return True





def test_valid_sms_event(event):
    valid_sms = {
        "SmsStatus": "received",
        "From":      os.environ["user_number"],
        "To":        os.environ["twilio_number"],
        "ToCountry": "US"
    }
    ## compare received event against valid sms fields 
    return compare_event_to_valid(valid_sms, event)



def test_valid_sns_event(event):
    sns = event["Sns"]
    valid_sns = {
        "Subject":    "AWS CloudFormation Notification",
        "TopicArn":   os.environ["sns_topic_arn"]
    }
    ## compare received event against valid event fields
    if not compare_event_to_valid(valid_sns, sns) or not "Message" in sns:
        return False


    valid_message = {
        "ResourceStatus": "CREATE_COMPLETE",
        "ResourceType":   "AWS::CloudFormation::Stack",
        "StackName":      "tmf-network"
    }
    ## parse event message details of the form Key='Value'\n...
    message_list = sns["Message"].split("\n")
    message_dict = {}
    for field in message_list:
        pair = field.split("=")
        if len(pair) == 2:
            message_dict[pair[0]] = pair[1].replace("'","")

    ## compare received message to valid message fields
    return compare_event_to_valid(valid_message, message_dict)




def test_valid_lambda_event(event):
    ## check request context 
    request = event["requestContext"]
    valid_request_context = {
            "functionArn": os.environ["tmf_app_lambda_arn"]
    }
    if not compare_event_to_valid(valid_request_context, request):
        return False

    ## check response payload
  #  response = event["responsePayload"]
#    if "errorMessage" in response:
    return True




def parse_event(event):
    ## handle SMS events
    if "SmsSid" in event and test_valid_sms_event(event):
        return "sms"

    ## handle SNS notifications
    if "Records" in event:
        event = event["Records"][0]
        if event["EventSource"] == "aws:sns" and test_valid_sns_event(event):
            return "sns"

    ## handle TMF invocation messages
    if "requestContext" in event and "functionArn" in event["requestContext"]:
        if test_valid_lambda_event(event):
            return "lambda"
    
    ## no valid event detected
    return False

    
