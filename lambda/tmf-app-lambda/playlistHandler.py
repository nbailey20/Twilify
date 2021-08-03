import spotipy
import json, os


def create_new_playlist(sp):
    try:
        res = sp.user_playlist_create(os.environ["spotify_user"], os.environ["playlist_name"], public=False) 
        playlist_id = res["id"]
    except:
        return False
    return playlist_id





## Function to return current, non-expired songs in Spotify playlist and local songbank
##  based on neutral refresh count and manual playlist deletes
def load_playlist(DEBUG, sp, songbank):
    playlist_id = songbank["playlistId"]
    saved_tracks = songbank["playlistTracks"]

    ## get list of current tracks in playlist
    if DEBUG: print("DEBUG: about to retrieve current tracks in playlist")
    try:
        res = sp.user_playlist_tracks(os.environ["spotify_user"], playlist_id=playlist_id)
        currentTracks = []
        res = res["items"]
        for track in res:
            currentTracks.append(track["track"]["id"])
        if DEBUG: print("DEBUG: successfully retrieved playlist tracks", currentTracks)
    except:
        return False
  
    ## Remove songs in saved songbank that are not longer in playlist
    ##  or have expired based on refresh count
    if DEBUG: print("DEBUG: about to compare and update local songbank data with actual playlist data")
    index = 0
    num_deleted = 0
    while index < len(saved_tracks):
        st = saved_tracks[index]
        if st["id"] not in currentTracks:
            saved_tracks = saved_tracks[:index] + saved_tracks[index+1:]
            num_deleted += 1
            if DEBUG: print("DEBUG: removing track", index, st["id"])
        else:
            index += 1
    if DEBUG: print("DEBUG: removed songs from local songbank that no longer exist in playlist")

    ## if TMF invoked (neutral refresh count incremented),
    ## remove any songs that have expired based on refresh count
    index = 0
    while index < len(saved_tracks):
        st = saved_tracks[index]
        if st["count"] >= int(os.environ["neutral_song_refresh_rate"])-1:
            try:
                sp.user_playlist_remove_all_occurrences_of_tracks(os.environ["spotify_user"], playlist_id, [st["id"]])
                saved_tracks = saved_tracks[:index] + saved_tracks[index+1:]
                if DEBUG: print("DEBUG: removed expired track from playlist and local songbank based on refresh count", st["id"])
            except:
                if DEBUG: print("DEBUG: could not remove expired track from playlist, continuing", st["id"])
                index += 1
        else:
            index += 1

    songbank["playlistTracks"] = saved_tracks
    if DEBUG: print("DEBUG: successfully retrieved valid tracks and updated local songbank", saved_tracks)
    return saved_tracks



def save_playlist(sp, playlist_id, tracks_to_add):
    ## If no tracks to add, we're done
    if len(tracks_to_add) > 0:
        try:
            sp.user_playlist_add_tracks(os.environ["spotify_user"], playlist_id, tracks_to_add)
        except:
            return False
    return True

