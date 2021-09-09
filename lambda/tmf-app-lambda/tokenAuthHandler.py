## Handles SSM Parameter Store get/put for Spotify refresh token
## Also contains authencation function for Spotify using refresh token

import boto3
from botocore.client import Config
from spotipy import Spotify
from spotipy.oauth2 import SpotifyOAuth
import os


## Function to retrieve encrypted Spotify refresh token saved in SSM Parameter Store
def retrieve_refresh_token(DEBUG):
    if DEBUG: print("DEBUG: looking for Spotify refresh token")
    try:
        parameter_name = os.environ["refresh_token_parameter_name"]
        if DEBUG: print("DEBUG: found refresh token parameter name", parameter_name)
    except:
        if DEBUG: print("DEBUG: not able to read parameter name environment variable")
        return False
    
    if DEBUG: print("DEBUG: about to retrieve token data from parameter store")
    config = Config(connect_timeout=3, retries={"max_attempts": 4})
    ssm = boto3.client("ssm", config=config)
    try:
        refresh_token = ssm.get_parameter(Name=parameter_name, WithDecryption=True)["Parameter"]["Value"]
        if DEBUG: print("DEBUG: successfully retrieved refresh token from parameter store")
        return refresh_token
    except:
        if DEBUG: print("DEBUG: could not retrieve refresh token from parameter store")
        return False
        

def update_refresh_token(DEBUG, next_refresh_token):
    config = Config(connect_timeout=3, retries={"max_attempts": 4})
    ssm = boto3.client("ssm", config=config)
    if DEBUG: print("DEBUG: about to save updated refresh token to parameter store")
    try:
        ssm.put_parameter(
            Name      = os.environ["refresh_token_parameter_name"],
            Value     = next_refresh_token,
            Type      = "SecureString",
            Overwrite = True,
            KeyId     = os.environ["refresh_token_kms_key_arn"],
        )
        if DEBUG: print("DEBUG: successfully saved refresh token to parameter store")
        return True
    except:
        if DEBUG: print("DEBUG: did not successfully update refresh token parameter")
        return False



## Function to return an API client and refresh token given Spotify Oauth creds
## [False, False] -> [sp, refresh_token] if successful
def auth_spotify(DEBUG, refresh_token):
    scope = "user-top-read playlist-modify-private playlist-modify-collaborative" 
    if DEBUG: print("DEBUG: about to create Spotify oauth client with refresh token")
    try:
        sp_oauth = SpotifyOAuth(
            os.environ["spotify_client_id"],
            os.environ["spotify_client_secret"],
            "http://127.0.0.1",
            scope=scope,
            cache_path=None,
            requests_timeout=5,
        )
        if DEBUG: print("DEBUG: successfully created oauth client")
    except:
        if DEBUG: print("DEBUG: could not create Spotify oauth client object")

    ret_list = [False,False] ## API client, next_refresh_token
    if DEBUG: print("DEBUG: about to get new access token with refresh token")
    try:
        token_info = sp_oauth.refresh_access_token(refresh_token)
        access_token = token_info["access_token"]
        ret_list[1] = token_info["refresh_token"]
        if DEBUG: print("DEBUG: got new access token object")
    except:
        if DEBUG: print("DEBUG: could not get access token or next refresh, returning False")
        return ret_list

    if DEBUG: print("DEBUG: about to create spotipy client")
    try:
        ## client by default has request timeout of 5 seconds, 3 retries per API call
        ret_list[0] = Spotify(auth=access_token)
        if DEBUG: print("DEBUG: successfully returning spotipy API client back to main")
    except:
        if DEBUG: print("DEBUG: could not create spotipy client with access token")
        return ret_list
    return ret_list