import boto3
import os, json
from eventHandler import parse_event
from textHandler import parse_text
import parameterHandler

## Terraform bools not capitalized unlike Python
DEBUG = True if os.environ["debug"] == "true" else False

    
def lambda_handler(event, _):
    if DEBUG: print("DEBUG: starting TMF reception main function")

    ## parse event type
    event_type = parse_event(DEBUG, event)
    if not event_type:
        return
    if DEBUG: print("DEBUG: parsed event type as", event_type)

    ## if user texted for more music, start creation of network stack
    if event_type == "sms":
        playlist_params = parse_text(DEBUG, event["Body"])
        choices_captured = "Message received!"
        if len(playlist_params.keys()) > 0:
            choices_captured = " ".join(playlist_params.keys()) + " requests captured"

        response_header = "<Response><Message><Body>"
        response_footer = "</Body></Message></Response>"

        stack_name            = "tmf-network"
        tmfNetworkCftUrl      = os.environ["s3_template_url"]
        tmfNetworkSnsTopic    = os.environ["sns_topic_arn"]
    
        cf = boto3.client("cloudformation")
        try:
            cf.create_stack(
                StackName=stack_name,
                TemplateURL=tmfNetworkCftUrl, 
                Parameters=[],
                NotificationARNs=[tmfNetworkSnsTopic]
            )
            if DEBUG: print("DEBUG: TMF Network Stack creating...")
        except:
            if DEBUG: print("DEBUG: could not create network connection CFT for app")
            return response_header + "Error: could not setup network connection, aborting." + response_footer

        ## save playlist parameter state
        if not parameterHandler.save_playlist_parameters(DEBUG, json.dumps(playlist_params)):
            if DEBUG: print("DEBUG: could not save text parameters, sending error text")
            return response_header + "Error: could not save playlist request(s), ignoring request." + response_footer
        
        if DEBUG: print("DEBUG: about to return success text")
        return response_header + "Warming up the ol' brain engine... " + choices_captured + response_footer


    ## if SNS notifies that network stack is done creating, then invoke TMF app
    if event_type == "sns":
        if DEBUG: print("DEBUG: TMF stack finished creating")

        ## load playlist parameters
        playlist_params_string = parameterHandler.load_playlist_parameters(DEBUG)
        if playlist_params_string is False:
            if DEBUG: print("DEBUG: could not load text parameters, aborting.")
            return False

        ## launch app with parameters
        try:
            if DEBUG: print("DEBUG: Launching TMF app")
            client = boto3.client("lambda")
            client.invoke(
                FunctionName="tmf",
                InvocationType="Event",
                Payload=playlist_params_string,
            )
            return
        except:
            if DEBUG: print("ERROR: failed to invoke TMF lambda function, intervention required to delete network stack.")
            return


    ## if TMF app sends successful invocation event, then destroy network stack to save $$
    if event_type == "lambda":
        stack_name = "tmf-network"
        if DEBUG: print("DEBUG: TMF app completed")
        try:
            cf = boto3.client("cloudformation")
            cf.delete_stack(
                StackName=stack_name,
            )
            if DEBUG: print("DEBUG: TMF Network Stack deleting")
            return
        ## if stack deletion fails
        except:
            if DEBUG: print("DEBUG: failed to delete network stack for TMF")
            return 


