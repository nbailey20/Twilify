import boto3
from botocore.client import Config
import os

def save_playlist_parameters(DEBUG, playlist_params_string):
    config = Config(connect_timeout=3, retries={"max_attempts": 4})
    ssm = boto3.client("ssm", config=config)
    if DEBUG: print("DEBUG: about to save playlist params to parameter store")
    try:
        ssm.put_parameter(
            Name      = os.environ["playlist_params_parameter_name"],
            Value     = playlist_params_string,
            Type      = "String",
            Overwrite = True,
        )
        if DEBUG: print("DEBUG: successfully saved playlist params to parameter store")
        return True
    except:
        return False


def load_playlist_parameters(DEBUG):
    if DEBUG: print("DEBUG: about to retrieve playlist params from parameter store")
    config = Config(connect_timeout=3, retries={"max_attempts": 4})
    ssm = boto3.client("ssm", config=config)
    try:
        playlist_params = ssm.get_parameter(Name=os.environ["playlist_params_parameter_name"], WithDecryption=True)["Parameter"]["Value"]
        if DEBUG: print("DEBUG: successfully retrieved playlist params from parameter store")
        return playlist_params
    except:
        return False
