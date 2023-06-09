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
    try:
        client = storage.Client()
        bucket = client.bucket(os.environ["bucket_name"])
        blob = bucket.blob(os.environ["songbank_file_name"])
        blob.upload_from_string(json.dumps(data))
        if DEBUG: print("DEBUG: successfully saved songbank to S3")
        return True
    except Exception as e:
        if DEBUG: print(f"DEBUG: error writing file to storage bucket: {e}")
        return False



## Returns file contents as dict if successful, False otherwise
def read_file(DEBUG):
    ## Read object from Storage after checking network connection
    if DEBUG: print("DEBUG: about to retrieve songbank object from Cloud Storage")
    try:
        client = storage.Client()
        bucket = client.bucket(os.environ["bucket_name"])
        blob = bucket.blob(os.environ["songbank_file_name"])
        file_data = blob.download_as_text()
        if DEBUG: print("DEBUG: successfully retrieved songbank object from Storage")
    except Exception as e:
        if DEBUG: print(f"DEBUG: failed to read songbank file from storage: {e}")
        return False

    try:
        json_content = json.loads(file_data)
        if DEBUG: print("DEBUG: successfully parsed songbank")
        return json_content
    except Exception as e:
        if DEBUG: print("DEBUG: could not parse songbank from file")
        return False
