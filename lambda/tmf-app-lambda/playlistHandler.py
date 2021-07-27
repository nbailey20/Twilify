import spotipy
import json, os


def create_new_playlist(sp):
    try:
        res = sp.user_playlist_create(os.environ["spotify_user"], os.environ["playlist_name"], public=False) 
        playlist_id = res["id"]
    except:
        return False
    return playlist_id





## Function to return number of songs to add to a given spotify playlist
##  based on expected number of songs in playlist and their neutral refresh counts
def load_playlist(sp, songbank):
    playlist_id = songbank["playlistId"]
    saved_tracks = songbank["playlistTracks"]

    ## get list of current tracks in playlist
    try:
        res = sp.user_playlist_tracks(os.environ["spotify_user"], playlist_id=playlist_id)
        currentTracks = []
        res = res["items"]
        for track in res:
            currentTracks.append(track["track"]["id"])
    except:
        return False
  
    ## Remove songs in saved songbank that are not longer in playlist
    ##  or have expired based on refresh count
    index = 0
    num_deleted = 0
    while index < len(saved_tracks):
        st = saved_tracks[index]
        if st['id'] not in currentTracks:
            saved_tracks = saved_tracks[:index] + saved_tracks[index+1:]
            num_deleted += 1
        else:
            index += 1
    
    ## If no songs manually removed, then we shouldn't remove anything else
    if num_deleted == 0:
        return saved_tracks

    ## if some songs were manually removed (neutral refresh count incremented),
    ## remove other songs that have expired based on refresh count
    index = 0
    while index < len(saved_tracks):
        st = saved_tracks[index]
        if st["count"] >= int(os.environ["neutral_song_refresh_rate"]):
            saved_tracks = saved_tracks[:index] + saved_tracks[index+1:]
            sp.user_playlist_remove_all_occurrences_of_tracks(os.environ["spotify_user"], playlist_id, [st["id"]])
        else:
            index += 1

    return saved_tracks



def save_playlist(sp, playlist_id, tracks_to_add):
    try:
        sp.user_playlist_add_tracks(os.environ["spotify_user"], playlist_id, tracks_to_add)
    except:
        return False
    return True

