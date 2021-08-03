import boto3, json, os
from botocore.exceptions import ClientError

## Taken from boto3 example, returns True if upload successful, else False
def write_file(data):
    s3= boto3.resource('s3')
    try:
        obj = s3.Object(os.environ["bucket_name"], os.environ["songbank_file_name"])
        obj.put(Body=(bytes(json.dumps(data).encode('utf-8'))))
    except:
        return False
    return True



## Returns file contents if successful, False otherwise
def read_file(DEBUG = False):
    if DEBUG: print("DEBUG: entered s3handler read file function")
    s3 = boto3.client('s3')
    if DEBUG: print("DEBUG: about to retrieve songbank object from S3")
    try:
        res = s3.get_object(Bucket=os.environ["bucket_name"], Key=os.environ["songbank_file_name"])
        if DEBUG: print("DEBUG: successfully retrieved songbank object from S3", res)
    except:
        if DEBUG: print("DEBUG: could not make s3 get object call")
        return False

    if DEBUG: print("DEBUG: about to try and load songbank")
    try:
        file_content = res['Body'].read().decode('utf-8')
        json_content = json.loads(file_content)
        if DEBUG: print("DEBUG: successfully loaded songbank")
    except:
        if DEBUG: print("DEBUG: could not load songbank from file")
        return False
    return json_content

