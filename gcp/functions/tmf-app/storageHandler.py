import urllib, time, os, json

from google.cloud import storage


def test_network_connectivity(DEBUG):
    i = 0
    while i < 10:
        try:
            urllib.request.urlopen("https://www.google.com", timeout=1)
            if DEBUG: print("DEBUG: passed network connectivity check")
            return True
        except: 
            if DEBUG: print("DEBUG: failed network connectivity test " + str(i+1))
            time.sleep(3)
            i += 1
            continue
    if DEBUG: print("DEBUG: too many network connectivity tests failed, giving up")
    return False



## Taken from google docs, returns True if upload successful, else False
def write_file(DEBUG, data):
    if DEBUG: print("DEBUG: about to save local songbank to Cloud Storage")
    client = storage.Client()
    bucket = client.bucket(os.environ["bucket_name"])
    blob = bucket.blob(os.environ["songbank_file_name"])
    blob.upload_from_string(json.dumps(data))
    if DEBUG: print("DEBUG: successfully saved songbank to S3")
    return True

    
    # try:
        
    #     return True
    # except:
    #     if DEBUG: print("DEBUG: did not successfully write file to S3")
    #     return False
    # return


## Returns file contents if successful, False otherwise
def read_file(DEBUG):
    ## Read object from Storage after checking network connection
    if DEBUG: print("DEBUG: about to retrieve songbank object from Cloud Storage")
    client = storage.Client()
    bucket = client.bucket(os.environ["bucket_name"])
    blob = bucket.blob(os.environ["songbank_file_name"])
    file_data = blob.download_as_text()
    if DEBUG: print("DEBUG: successfully retrieved songbank object from Storage")
    print(file_data)

    json_content = json.loads(file_data)
    if DEBUG: print("DEBUG: successfully parsed songbank")
    return json_content

    # try:
        
    # except:
    #     if DEBUG: print("DEBUG: could not retrieve songbank from S3")
    #     return False

    ## Parse songbank file into json object
    # if DEBUG: print("DEBUG: about to try and parse songbank file")
    # try:
    #     file_content = res['Body'].read().decode('utf-8')
    #     json_content = json.loads(file_content)
    #     if DEBUG: print("DEBUG: successfully parsed songbank")
    # except:
    #     if DEBUG: print("DEBUG: could not parse songbank from file")
    #     return False
    # return json_content