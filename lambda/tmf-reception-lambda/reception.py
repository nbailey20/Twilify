import boto3, botocore, os
import eventParser

    
def lambda_handler(event, context):
    print("DEBUG: starting TMF reception main function, Received event: " + str(event))

    ## parse event type
    event_type = eventParser.parse_event(event)
    if not event_type:
        return
    print("DEBUG: parsed event type as", event_type)

    ## if user texted for more music, start creation of network stack
    if event_type == "sms":
        success_response_text = "<Response><Message><Body>Message received, warming up the ol' brain engine...</Body></Message></Response>"
        failure_response_text = "<Response><Message><Body>Sorry, brain engine isn't working currently...</Body></Message></Response>"

        stack_name            = "tmf-network"
        tmfNetworkCftUrl      = os.environ["s3_template_url"]
        tmfNetworkSnsTopic    = os.environ["sns_topic_arn"]
    
        cf = boto3.client('cloudformation')
        try:
            cf.create_stack(
                StackName=stack_name,
                TemplateURL=tmfNetworkCftUrl, 
                Parameters=[],
                NotificationARNs=[tmfNetworkSnsTopic]
            )
            print("TMF Network Stack creating...")
        except botocore.exceptions.ClientError as ex:
            print(ex)
            return failure_response_text
        print("DEBUG: about to return success text", success_response_text)
        return success_response_text


    ## if SNS notifies that network stack is done creating, then invoke TMF app
    if event_type == "sns":
        print("TMF stack finished creating")
        try:
            print("Launching TMF app...")
            client = boto3.client("lambda")
            client.invoke(
                FunctionName="tmf",
                InvocationType="Event"
            )
        except botocore.exceptions.ClientError as ex:
            print(ex)
        return


    ## if TMF app sends successful invocation event, then destroy network stack to save $$
    if event_type == "lambda":
        stack_name = "tmf-network"
        print("TMF app completed")
        try:
            cf = boto3.client('cloudformation')
            cf.delete_stack(
                StackName=stack_name,
            )
            print("TMF Network Stack deleting...")
        ## if stack creation fails, create new twilio message to alert user
        except botocore.exceptions.ClientError as ex:
            print(ex)
#            client = Client(account_sid, auth_token)

#            message = client.messages.create(
#                body="TMF Error Deleting Network Stack, intervention required.",
#                from_=os.environ["twilio_number"],
#                to=os.environ["user_number"]
 #           )
        return 


