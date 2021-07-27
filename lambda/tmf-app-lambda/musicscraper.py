import spotipy
import json, os
import s3Handler, playlistHandler
from spotipy.oauth2 import SpotifyOAuth


## Function to return an API client and refresh token given Spotify Oauth creds
def auth_spotify(refresh_token):
    print("made it to auth spotify")
    scope = "user-top-read playlist-modify-private" 

    sp_oauth = SpotifyOAuth(
        os.environ["client_id"],
        os.environ["client_secret"],
        "http://127.0.0.1",
        scope=scope,
        cache_path=None,
    )
    print("got oauth client")

    ret_list = [False,False] ## API client, next_refresh_token
    try:
        token_info = sp_oauth.refresh_access_token(refresh_token)
    except:
        print("no access token")
        return ret_list

    access_token = token_info["access_token"]
    ret_list[1] = token_info["refresh_token"]

    try:
        ret_list[0] = spotipy.Spotify(auth=access_token)
    except:
        return ret_list
    return ret_list




## Return a list of current user's top track Spotify IDs given API client object
def get_fav_tracks(sp):
    fav_tracks = []

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

    return fav_tracks



##  Takes json songbank file object and Spotify API client
##  initializes, creates spotify playlist if first time
##  Returns songbank object
def load_songbank(sp, songbank_json): 
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

    ## If first time running, create Spotify playlist and initialize songbank
    playlist_id = None
    if "playlistId" not in songbank_json:
        print(songbank_json)
        playlist_id = playlistHandler.create_new_playlist(sp)
        print("survived playlist creation")

    ## if songbank already exists and isn't expired, return it
    else:
        playlist_id = songbank_json["playlistId"]
        if songbank_json["numCycles"] < int(os.environ["songbank_cycles_before_rebuild"]):
            return songbank_json

    ## if songbank not initialized or expired, then build
    print("about to return from load songbank")
    return {
        "new": get_fav_tracks(sp), 
        "used": [], 
        "numCycles": 0, 
        "playlistId": playlist_id, 
        "playlistTracks": [], 
        "refreshToken": songbank_json["refreshToken"]
    }




##  Writes songbank to S3 bucket to save state for next time
##  adds recently recommended songs to playlistTracks
##  updates Spotify refresh token for next invocation
def save_songbank(songbank, songs_to_add, next_refresh_token):

    ## Update neutral song refresh count for songs still in playlist
    for song in songbank["playlistTracks"]:
        song["count"] += 1
    ## Add new songs to playlist
    for song in songs_to_add:
        songbank["playlistTracks"].append({"id": song, "count": 0})

    ## Update refresh token with next value
    songbank["refreshToken"] = next_refresh_token

    if s3Handler.write_file(songbank):
        return True
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


