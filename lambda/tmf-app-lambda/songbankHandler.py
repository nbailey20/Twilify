## Handles songbank creation, loading, and saving operations
## Also kicks off call to create playlist if first time or no longer exists but should

import s3Handler, playlistHandler, musicQueryHandler, tokenAuthHandler
import os

##  Takes json songbank file object and Spotify API client
##  initializes, creates spotify playlist if first time
##  Returns songbank object
def load_songbank(DEBUG, sp, songbank_json, params): 
    """
    {
        "new":                [string],
        "used":               [string],
        "numCycles":          int,
        "playlistId":         string,
        "playlistListTracks": [{"name": string, "id": string, "count": int, "seeds": [string]}]
    }
    """

    
    ## Get saved Spotify playlist ID, or try to look it up if overwrite keyword provided
    if DEBUG: print("DEBUG: looking for saved Spotify playlist ID")
    try: 
        playlist_id = songbank_json["playlistId"]
    except:
        if DEBUG: print("DEBUG: did not find existing playlist ID in songbank")

        if "overwrite" in params:
            if DEBUG: print("DEBUG: overwrite keyword provided, checking Spotify for pre-existing playlist with expected name in user account")
            playlist_id = playlistHandler.search_for_previous_playlist(DEBUG, sp)

            ## If no Spotify playlist ID saved or found, create one
            if not playlist_id:
                if DEBUG: print("DEBUG: creating new playlist to avoid overwriting anything important")
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

    ## if songbank not initialized, then get new seeds
    if expired == None:
        if DEBUG: print("DEBUG: initializing new songbank")
        new_tracks = musicQueryHandler.get_fav_tracks(DEBUG, sp)
        if new_tracks:
            return {
                "new": new_tracks, 
                "used": [], 
                "numCycles": 0, 
                "playlistId": playlist_id, 
                "playlistTracks": [], 
            }
        else:
            if DEBUG: print("DEBUG: could not create new songbank data")
            return False

    ## if songbank expired, then get new seeds and keep track of current playlist
    elif expired == True:
        if DEBUG: print("DEBUG: rebuilding expired songbank")
        new_tracks = musicQueryHandler.get_fav_tracks(DEBUG, sp)
        if new_tracks:
            return {
                "new": new_tracks, 
                "used": [], 
                "numCycles": 0, 
                "playlistId": playlist_id, 
                "playlistTracks": songbank_json["playlistTracks"], 
            }
        else:
            if DEBUG: print("DEBUG: could not rebuild songbank data")
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
    if DEBUG: print("DEBUG: trying to update and save songbank to S3")

    ## Update neutral song refresh count for songs still in playlist
    for song in songbank["playlistTracks"]:
        song["count"] += 1
    ## Add new songs to playlist
    for song_data in songs_to_add:
        songbank["playlistTracks"].append({"name": song_data["name"], "id": song_data["id"], "count": 0, "seeds": song_data["seeds"]})

    ## Update refresh token SSM parameter with next value
    if not tokenAuthHandler.update_refresh_token(DEBUG, next_refresh_token):
        return False

    ## Save songbank to S3 for next invocation
    if s3Handler.write_file(DEBUG, songbank):
        return True
    return False