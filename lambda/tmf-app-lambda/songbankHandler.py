## Handles songbank creation, loading, and saving operations
## Also kicks off call to create playlist if first time or no longer exists but should

import s3Handler, playlistHandler, musicQueryHandler
import os

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
        playlist_id = playlistHandler.create_new_playlist(DEBUG, sp)
        
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
        new_tracks = musicQueryHandler.get_fav_tracks(DEBUG, sp)
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
        if DEBUG: print("DEBUG: retrieving previous songbank data", songbank_json)
        return songbank_json




##  Writes songbank to S3 bucket to save state for next time
##  adds recently recommended songs to playlistTracks
##  updates Spotify refresh token for next invocation
def save_songbank(DEBUG, songbank, songs_to_add, next_refresh_token):
    if DEBUG: print("DEBUG: trying to update and save songbank to S3")

    ## Update neutral song refresh count for songs still in playlist
    for song in songbank["playlistTracks"]:
        song["count"] += 1
    ## Add new songs to playlist
    for song in songs_to_add:
        songbank["playlistTracks"].append({"id": song, "count": 0})

    ## Update refresh token with next value
    songbank["refreshToken"] = next_refresh_token
    if DEBUG: print("DEBUG: updated songbank locally")

    ## Save songbank to S3 for next invocation
    if s3Handler.write_file(DEBUG, songbank):
        return True
    return False