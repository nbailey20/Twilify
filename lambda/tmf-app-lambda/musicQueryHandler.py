## Handles Spotify API authentication and all Music recommendation & search operations

import spotipy
import json, os
import s3Handler, playlistHandler
from spotipy.oauth2 import SpotifyOAuth
from random import randrange


## Function to return an API client and refresh token given Spotify Oauth creds
## [False, False] -> [sp, refresh_token] if successful
def auth_spotify(DEBUG, refresh_token):
    scope = "user-top-read playlist-modify-private" 
    if DEBUG: print("DEBUG: about to create Spotify oauth client with refresh token", refresh_token)
    try:
        sp_oauth = SpotifyOAuth(
            os.environ["client_id"],
            os.environ["client_secret"],
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
        if DEBUG: print("DEBUG: got token info", token_info)
    except:
        if DEBUG: print("DEBUG: could not get access token or next refresh, returning False")
        return ret_list

    if DEBUG: print("DEBUG: about to create spotipy client")
    try:
        ## client by default has request timeout of 5 seconds, 3 retries per API call
        ret_list[0] = spotipy.Spotify(auth=access_token)
        if DEBUG: print("DEBUG: successfully returning spotipy API client back to main", ret_list)
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


def get_song_rec_from_seeds(DEBUG, sp, songbank):
    if DEBUG: print("DEBUG: attempting to get new track recommendation")
    attempts = 0
    while attempts < 5:

        ## Get random seed size [1,3] for song generation
        seedSize = randrange(3)+1

        ## Make sure we have seedSize songs in new songbank list to choose from
        ## if not, add all used songs back to new before choosing
        if seedSize > len(songbank["new"]):
            songbank["new"] += songbank["used"]
            songbank["used"] = []
            songbank["numCycles"] += 1

        ## Get seedSize # of random new track IDs, remove IDs from new list in songbank
        seeds = []
        for _ in range(seedSize):
            index = randrange(len(songbank["new"]))
            seeds.append(songbank["new"][index])
            songbank["new"] = songbank["new"][:index] + songbank["new"][index+1:]

        ## Get track recommendations based on seed(s) (default 5)
        ## If no recommendations available, start over with different seeds until max attempts reached
        recs = get_track_recs(sp, seeds)
        if not recs:
            if DEBUG: print("DEBUG: did not find results with current seeds attempt " + str(attempts+1) + ", retrying")
            attempts += 1
            continue

        ## Move used seed(s) to used list in songbank
        songbank["used"] += seeds

        ## Choose random recommended track
        recSize = len(recs)
        index = randrange(recSize)
        suggested = recs[index]
        if DEBUG: print("DEBUG: found potential track")

        ## Make sure song isn't already in songbank
        already_exists = False
        for st in songbank['playlistTracks']:
            if st['id'] == suggested:
                already_exists = True
                if DEBUG: print("DEBUG: song is already in playlist, try again lol")
                break
        ## return suggested song and updated songbank
        if not already_exists:
            if DEBUG: print("DEBUG: found good track recommendation")
            return [suggested, songbank]

    ## If could not get recommendation, don't try forever
    if DEBUG: print("DEBUG: could not get track recommendation, giving up")
    return [False, False]