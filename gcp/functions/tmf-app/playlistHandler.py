## Handles Spotify playlist operations: create, save, load
import os


def create_new_playlist(DEBUG, sp):
    try:
        res = sp.user_playlist_create(os.environ["spotify_user"], os.environ["playlist_name"], public=False) 
        playlist_id = res["id"]
        if DEBUG: print("DEBUG: successfully created playlist")
        return playlist_id
    except Exception as e:
        if DEBUG: print(f"DEBUG: could not create new Spotify playlist: {e}")
        return


def search_for_previous_playlist(DEBUG, sp):
    try:
        name = os.environ["playlist_name"]
        res = sp.user_playlists(os.environ["spotify_user"])
        while res:
            for playlist in res["items"]:
                if playlist["name"] == name:
                    if DEBUG: print("DEBUG: found existing playlist to overwrite")
                    return playlist["id"]
            if res["next"]:
                res = sp.next(res)
            else:
                res = None
        if DEBUG: print("DEBUG: did not find existing playlist with appropriate name")
        return False
    except Exception as e:
        if DEBUG: print(f"DEBUG: error while searching existing user playlists, continuing: {e}")
        return False



## Function to return current, non-expired songs in Spotify playlist and local songbank
##  based on manual playlist deletes
def load_playlist(DEBUG, sp, songbank, params):
    if DEBUG: print("DEBUG: trying to load Spotify playlist")
    playlist_id = songbank["playlistId"]
    saved_tracks = songbank["playlistTracks"]

    ## If keep keyword set, don't remove songs from playlist by default
    if not "keep" in params:
        if DEBUG: print("DEBUG: keep keyword not provided, about to replace all tracks in playlist")
        try:
            sp.user_playlist_replace_tracks(os.environ["spotify_user"], playlist_id=playlist_id, tracks=[])
        except Exception as e:
            if DEBUG: print(f"DEBUG: failed to replace all tracks: {e}")

    ## get list of current tracks in playlist
    if DEBUG: print("DEBUG: about to retrieve current tracks in playlist")
    try:
        res = sp.user_playlist_tracks(os.environ["spotify_user"], playlist_id=playlist_id)
        currentTracks = []
        res = res["items"]
        for track in res:
            currentTracks.append(track["track"]["id"])
        if DEBUG: print("DEBUG: successfully retrieved playlist tracks")
    except Exception as e:
        if DEBUG: print(f"DEBUG: failed to retrieve playlist tracks: {e}")
        return False
  
    ## Remove songs in saved songbank that are no longer in playlist
    if DEBUG: print("DEBUG: about to compare and update local songbank data with actual playlist data")
    index = 0
    num_deleted = 0
    while index < len(saved_tracks):
        st = saved_tracks[index]
        if st["id"] not in currentTracks:
            saved_tracks = saved_tracks[:index] + saved_tracks[index+1:]
            num_deleted += 1
            if DEBUG: print("DEBUG: removing track")
        else:
            index += 1
    if DEBUG: print("DEBUG: removed songs from local songbank that no longer exist in playlist")

    songbank["playlistTracks"] = saved_tracks
    if DEBUG: print("DEBUG: successfully retrieved valid tracks and updated local songbank")
    return saved_tracks



def save_playlist(DEBUG, sp, playlist_id, tracks_to_add):
    if DEBUG: print("DEBUG: about to update Spotify playlist with new tracks")
    ## If no tracks to add, we're done
    if len(tracks_to_add) > 0:
        track_ids = [x["id"] for x in tracks_to_add]
        try:
            sp.user_playlist_add_tracks(os.environ["spotify_user"], playlist_id, track_ids)
            if DEBUG: print("DEBUG: successfully updated playlist")
        except Exception as e:
            if DEBUG: print(f"DEBUG: could not update playlist: {e}")
            return False
    return True
