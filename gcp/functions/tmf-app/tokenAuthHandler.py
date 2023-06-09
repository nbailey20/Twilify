## Handles adding new Secret Manager version for Spotify refresh token
## Also contains authencation function for Spotify using refresh token

import os, base64

from google.cloud import secretmanager_v1
from spotipy import Spotify
from spotipy.oauth2 import SpotifyOAuth


## Function to return an API client and refresh token given Spotify Oauth creds
## [False, False] -> [sp, refresh_token] if successful
def auth_spotify(DEBUG, refresh_token):
    scope = "user-top-read playlist-modify-private playlist-modify-public playlist-read-private playlist-read-collaborative" 
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

    if DEBUG: print("DEBUG: about to get new access token from refresh token")
    try:
        token_info = sp_oauth.refresh_access_token(refresh_token)
        access_token = token_info["access_token"]
        if DEBUG: print("DEBUG: got new access token object")
    except:
        if DEBUG: print("DEBUG: could not get access token, returning False")
        return False

    if DEBUG: print("DEBUG: about to create spotipy client")
    try:
        ## client by default has request timeout of 5 seconds, 3 retries per API call
        sp = Spotify(auth=access_token)
        if DEBUG: print("DEBUG: successfully returning spotipy API client back to main")
    except:
        if DEBUG: print("DEBUG: could not create spotipy client with access token")
        return False
    return sp