import boto3, json, os
from botocore.exceptions import ClientError

## Taken from boto3 example, returns True if upload successful, else False
def write_file(data):
    s3= boto3.resource('s3')
    try:
        obj = s3.Object(os.environ["bucket_name"], os.environ["songbank_file_name"])
        obj.put(Body=(bytes(json.dumps(data).encode('utf-8'))))
    except ClientError as e:
        print(e)
        return False
    return True



## Returns file contents if successful, False otherwise
def read_file():
    print("DEBUG: entered s3handler read file function")
    s3 = boto3.client('s3')
    print("DEBUG: about to retrieve songbank object from S3")
   # try:
    res = s3.get_object(Bucket=os.environ["bucket_name"], Key=os.environ["songbank_file_name"])
    print("DEBUG: successfully retrieved songbank object from S3", res)
    file_content = res['Body'].read().decode('utf-8')
    json_content = json.loads(file_content)
    print("DEBUG: successfully loaded songbank")
    #except ClientError as e:
    #print(e)
    #    return False
    return json_content

