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
    print("made it into read file func")
    s3 = boto3.client('s3')
    print("wtf?")
   # try:
    res = s3.get_object(Bucket=os.environ["bucket_name"], Key=os.environ["songbank_file_name"])
    print('timing out?')
    print(res)
    file_content = res['Body'].read().decode('utf-8')
    print("test")
    json_content = json.loads(file_content)
    #except ClientError as e:
    print("got an error but nothing printing here for some reason")
    #print(e)
    #    return False
    return json_content

