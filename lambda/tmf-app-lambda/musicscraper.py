import spotipy
import json, os
import s3Handler, playlistHandler
from spotipy.oauth2 import SpotifyOAuth


## Function to return an API client and refresh token given Spotify Oauth creds
## [False, False] -> [sp, refresh_token] if successful
def auth_spotify(DEBUG, refresh_token):
    if DEBUG: print("DEBUG: made it to auth spotify function with refresh token", refresh_token)
    scope = "user-top-read playlist-modify-private" 

    if DEBUG: print("DEBUG: about to create Spotify oauth client")
    try:
        sp_oauth = SpotifyOAuth(
            os.environ["client_id"],
            os.environ["client_secret"],
            "http://127.0.0.1",
            scope=scope,
            cache_path=None,
        )
        if DEBUG: print("DEBUG: got oauth client")
    except:
        if DEBUG: print("DEBUG: could not create Spotify oauth client object")

    ret_list = [False,False] ## API client, next_refresh_token
    if DEBUG: print("DEBUG: about to refresh access token with refresh token")
    try:
        token_info = sp_oauth.refresh_access_token(refresh_token)
        access_token = token_info["access_token"]
        ret_list[1] = token_info["refresh_token"]
        if DEBUG: print("DEBUG: got token info", token_info)
    except:
        print("DEBUG: could not get access token or next refresh, returning False")
        return ret_list

    if DEBUG: print("DEBUG: about to create spotipy client")
    try:
        ret_list[0] = spotipy.Spotify(auth=access_token)
        if DEBUG: print("DEBUG: successfully returning spotipy client back to main", ret_list)
    except:
        if DEBUG: print("DEBUG: could not create spotipy client with access token", access_token)
        return ret_list
    return ret_list




## Return a list of current user's top track Spotify IDs given API client object
def get_fav_tracks(DEBUG, sp):
    fav_tracks = []
    try:
        tracks = sp.current_user_top_tracks(limit=30, time_range="long_term")
        tracks = tracks["items"]
        for track in tracks:
            fav_tracks.append(track["id"])

        tracks = sp.current_user_top_tracks(limit=20, time_range="medium_term")
        tracks = tracks["items"]
        for track in tracks:
            fav_tracks.append(track["id"])

        tracks = sp.current_user_top_tracks(limit=10, time_range="short_term")
        tracks = tracks["items"]
        for track in tracks:
            fav_tracks.append(track["id"])
        
        if DEBUG: print("DEBUG: successfully retrieved user's fav tracks")
        return fav_tracks
    except:
        if DEBUG: print("DEBUG: could not get user's favorite tracks, aborting")
        return False



##  Takes json songbank file object and Spotify API client
##  initializes, creates spotify playlist if first time
##  Returns songbank object
def load_songbank(DEBUG, sp, songbank_json): 
    """
    {
        "new":                [string],
        "used":               [string],
        "numCycles":          int,
        "playlistId":         string,
        "playlistListTracks": [{"id": string, "count": int}],
        "refreshToken":       string
    }
    """

    ## If no saved Spotify playlist ID, create one
    if DEBUG: print("DEBUG: looking for saved Spotify playlist ID")
    try: 
        playlist_id = songbank_json["playlistId"]
    except:
        if DEBUG: print("DEBUG: did not find existing playlist ID, creating new playlist")
        playlist_id = playlistHandler.create_new_playlist(sp)
        if not playlist_id: 
            playlist_id = ""
            if DEBUG: print("DEBUG: could not create new Spotify playlist, continuing to build songbank for future runs")

    ## if songbank already exists and isn't expired, return it
    if DEBUG: print("DEBUG: checking for expired songbank")
    expired = None
    try:
        if songbank_json["numCycles"] < int(os.environ["songbank_cycles_before_rebuild"]):
            if DEBUG: print("DEBUG: found non-expired songbank")
            expired = False
        else:
            if DEBUG: print("DEBUG: found expired songbank")
            expired = True
    except:
        if DEBUG: print("DEBUG: did not find any known songbank data")

    ## if songbank not initialized or expired, then build
    if expired == None or expired == True:
        if DEBUG: print("DEBUG: creating new songbank data")
        new_tracks = get_fav_tracks(DEBUG, sp)
        if new_tracks:
            return {
                "new": new_tracks, 
                "used": [], 
                "numCycles": 0, 
                "playlistId": playlist_id, 
                "playlistTracks": [], 
                "refreshToken": songbank_json["refreshToken"]
            }
        else:
            if DEBUG: print("DEBUG: could not create new songbank data")
            return False
    else:
        ## make sure up-to-date Spotify playlist ID in songbank
        songbank_json["playlistID"] = playlist_id
        if DEBUG: print("DEBUG: retrieving previous songbank data")
        return songbank_json




##  Writes songbank to S3 bucket to save state for next time
##  adds recently recommended songs to playlistTracks
##  updates Spotify refresh token for next invocation
def save_songbank(DEBUG, songbank, songs_to_add, next_refresh_token):
    ## Update neutral song refresh count for songs still in playlist
    for song in songbank["playlistTracks"]:
        song["count"] += 1
    ## Add new songs to playlist
    for song in songs_to_add:
        songbank["playlistTracks"].append({"id": song, "count": 0})

    ## Update refresh token with next value
    songbank["refreshToken"] = next_refresh_token

    ## Save songbank to S3 for next invocation
    if DEBUG: print("DEBUG: updated songbank locally, about to save to S3")
    if s3Handler.write_file(songbank):
        if DEBUG: print("DEBUG: successfully saved songbank to S3")
        return True
    if DEBUG: print("DEBUG: did not successfully write file to S3")
    return False




## Return a list of Spotify track recommendations based on a seed of 1+ track IDs
def get_track_recs(sp, seeds):
    recs = []
    try:
        tracks = sp.recommendations(seed_tracks=seeds, limit=os.environ["rec_limit"])
        for track in tracks['tracks']:
            recs.append(track['id'])
        return recs
    except:
        return False