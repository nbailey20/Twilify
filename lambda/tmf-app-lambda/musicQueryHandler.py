## Handles all Spotify API Music recommendation & search operations

import os
from random import randrange


## Return a list of current user's top track Spotify IDs given authenticated API client object
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


## Selects random songs saved in songbank as seeds for Spotify query
## Updates songbank to ensure all seeds used equally
## If song result exists and doesn't exist in current playlist, it is returned
def get_song_rec_from_seeds(DEBUG, sp, songbank):
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