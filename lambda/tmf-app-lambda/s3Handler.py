## Handles all S3 read/write operations with network connectivity checks

import boto3, json, os, urllib, time
from botocore.client import Config

def test_network_connectivity(DEBUG):
    i = 0
    while i < 10:
        try:
            urllib.request.urlopen("https://s3.us-east-1.amazonaws.com", timeout=1)
            if DEBUG: print("DEBUG: passed network connectivity check")
            return True
        except: 
            if DEBUG: print("DEBUG: failed network connectivity test " + str(i+1))
            time.sleep(3)
            i += 1
            continue
    if DEBUG: print("DEBUG: too many network connectivity tests failed, giving up")
    return False



## Taken from boto3 example, returns True if upload successful, else False
def write_file(DEBUG, data):
    config = Config(connect_timeout=3, retries={'max_attempts': 4})
    s3 = boto3.resource('s3', config=config)
    if DEBUG: print("DEBUG: about to save local songbank to S3")
    try:
        obj = s3.Object(os.environ["bucket_name"], os.environ["songbank_file_name"])
        obj.put(Body=(bytes(json.dumps(data).encode('utf-8'))))
        if DEBUG: print("DEBUG: successfully saved songbank to S3", data)
        return True
    except:
        if DEBUG: print("DEBUG: did not successfully write file to S3")
        return False



## Returns file contents if successful, False otherwise
def read_file(DEBUG):
    ## Read object from S3 after checking network connection
    if DEBUG: print("DEBUG: about to retrieve songbank object from S3")
    config = Config(connect_timeout=3, retries={'max_attempts': 4})
    s3 = boto3.client('s3', config=config)
    try:
        res = s3.get_object(Bucket=os.environ["bucket_name"], Key=os.environ["songbank_file_name"])
        if DEBUG: print("DEBUG: successfully retrieved songbank object from S3")
    except:
        if DEBUG: print("DEBUG: could not retrieve songbank from S3")
        return False

    ## Parse songbank file into json object
    if DEBUG: print("DEBUG: about to try and parse songbank file")
    try:
        file_content = res['Body'].read().decode('utf-8')
        json_content = json.loads(file_content)
        if DEBUG: print("DEBUG: successfully parsed songbank")
    except:
        if DEBUG: print("DEBUG: could not parse songbank from file")
        return False
    return json_content

