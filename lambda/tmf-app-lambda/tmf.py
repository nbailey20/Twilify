import json, sys, os, time
import musicscraper, playlistHandler, twilioHandler, s3Handler
from random import randrange
import urllib

## Genres we don't want event notifications for, even if the artist is popular af
BLACKLIST = ["black-metal", "bluegrass", "death-metal", "country", "heavy-metal", "metal", "alternative country"]

DEBUG = os.environ["debug"]


def test_network_connectivity():
    i = 0
    while i < 10:
        try:
            urllib.request.urlopen("https://s3.us-east-1.amazonaws.com", timeout=1)
            return True
        except: 
            if DEBUG: print("DEBUG: failed network connectivity test " + str(i))
            time.sleep(3)
            i += 1
            continue
    return False


def get_song_rec_from_seeds(sp, songbank):
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
        recs = musicscraper.get_track_recs(sp, seeds)
        if not recs:
            attempts += 1
            continue

        ## Move used seed(s) to used list in songbank
        songbank["used"] += seeds

        ## Choose random recommended track
        recSize = len(recs)
        index = randrange(recSize)
        suggested = recs[index]

        ## Make sure song isn't already in songbank
        already_exists = False
        for st in songbank['playlistTracks']:
            if st['id'] == suggested:
                already_exists = True
                break
        ## return suggested song and updated songbank
        if not already_exists:
            return [suggested, songbank]

    ## If could not get recommendation, don't try forever
    return [False, False]


############################################################# START MAIN CODE BLOCK ##########################################################
def lambda_handler(event, context):
    if DEBUG: print("DEBUG: starting lambda_handler beginning function", event)

    ## Test network connectivity
    if DEBUG: print("DEBUG: about to test network connectivity")
    if not test_network_connectivity():
        if DEBUG: print("DEBUG: aborting after no connectivity multiple tries, about to send error text")
        twilioHandler.send_error_message("Could not connect to Internet after multiple tries, aborting.")
        sys.exit(1)
    if DEBUG: print("DEBUG: network connectivity established")


    ## Load songbank file
    if DEBUG: print("DEBUG: about to call s3handler read file")
    songbank_json = s3Handler.read_file(DEBUG)
    if DEBUG: print("DEBUG: returned to main function from s3handler read_file")

    if not songbank_json:
        if DEBUG: print("DEBUG: could not retrieve songbank json from S3, about to send error text")
        twilioHandler.send_error_message("Could not read songbank file from S3, aborting.")
        sys.exit(1)

    if DEBUG: print("DEBUG: about to retrieve previous refresh token")
    try:
        current_refresh_token = songbank_json["refreshToken"]
        if DEBUG: print("DEBUG: successfully retrieved saved refresh token from S3", current_refresh_token)
    except:
        if DEBUG: print("DEBUG: could not retrieve Spotify refresh token, about to send error text")
        twilioHandler.send_error_message("Could not retrieve Spotify refresh token data, aborting.")
        sys.exit(1)


    ## Authenticate to Spotify
    if DEBUG: print("DEBUG: about to call musicscraper auth spotify from main")
    sp, next_refresh_token = musicscraper.auth_spotify(DEBUG, current_refresh_token)
    if DEBUG: print("DEBUG: back to main from musicscraper auth spotify call")
    if not next_refresh_token:
        print("DEBUG: could not retrieve next refresh token from auth spotify, about to send error text")
        twilioHandler.send_error_message("Could not get new access token from Spotify")
        sys.exit(1)
    if not sp:
        print("DEBUG: could not retrieve api client object from auth spotify call, about to send error text")
        twilioHandler.send_error_message("Could not create API client with Spotify token")
        sys.exit(1)


    ## Initialize Songbank
    ## API client needed to create playlist if first time
    if DEBUG: print("DEBUG: about to call musicscraper load songbank")
    songbank = musicscraper.load_songbank(DEBUG, sp, songbank_json)
    if DEBUG: print("DEBUG: back to main from musicscraper load songbank call")
    if not songbank:
        if DEBUG: print("DEBUG: did not return anything from load songbank call, about to send error text")
        twilioHandler.send_error_message("Cannot load songbank, aborting.")
        sys.exit(1)
    if DEBUG: print("DEBUG: loaded songbank", songbank)


    ## Load playlist information
    if DEBUG: print("DEBUG: about to call playlisthandler load playlist")
    playlistTracks = playlistHandler.load_playlist(DEBUG, sp, songbank) 
    if DEBUG: print("DEBUG: returned to main from playlisthandler load playlist call")
    ## Check explicitly for False since empty list is also False
    if playlistTracks is False:
        print("DEBUG: could not retrieve tracks from playlist, about to send error text")
        twilioHandler.send_error_message("Cannot load playlist, aborting.")
        sys.exit(1)


    ## For each song to add, get a recommendation
    num_songs_to_add = int(os.environ["num_songs_in_playlist"]) - len(playlistTracks) 
    if DEBUG: print("DEBUG: will attempt to add " + str(num_songs_to_add) + " songs to the playlist")

    songs_to_add = []
    for _ in range(num_songs_to_add):
        if DEBUG: print("DEBUG: about to get song rec from seeds")
        new_song_id, songbank = get_song_rec_from_seeds(sp, songbank)
        if new_song_id:
            songs_to_add.append(new_song_id)
        elif DEBUG: print("DEBUG: could not get song rec, continuing")
    if DEBUG: print("DEBUG: finished collecting song recs", songs_to_add)


    ## Add new songs to songbank and write data to S3 for next time
    ## update Spotify refresh token for next invocation
    if DEBUG: print("DEBUG: about to call musicscraper save songbank to S3")
    if not musicscraper.save_songbank(DEBUG, songbank, songs_to_add, next_refresh_token):
        if DEBUG: print("DEBUG: could not save songbank to s3, about to send error text")
        twilioHandler.send_error_message("Could not save songbank to S3")
        sys.exit(1)


    ## Add recommended songs to Spotify playlist
    if DEBUG: print("DEBUG: about to call playlisthandler to update playlist in Spotify")
    if not playlistHandler.save_playlist(sp, songbank["playlistId"], songs_to_add):
        if DEBUG: print("DEBUG: could not save Spotify playlist, about to send error text")
        twilioHandler.send_error_message("Updated songbank with new content but could not push to playlist")
        sys.exit(1)


    ## All done!
    if num_songs_to_add == 0:
        if DEBUG: print("DEBUG: no tracks to add to playlist, texting user TMF has nothing to do")
        twilioHandler.send_completed_message(DEBUG, "No tracks to update this time!")
    else:
        if DEBUG: print("DEBUG: successfully completed TMF iteration, about to send success text")
        twilioHandler.send_completed_message(DEBUG, "Enjoy your new " + str(num_songs_to_add) + " songs :)")
    return {
        "status": "200",
        "body": "success"
    }
