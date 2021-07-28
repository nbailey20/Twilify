import json, sys, os
import musicscraper, playlistHandler, twilioHandler, s3Handler
from random import randrange

## Genres we don't want event notifications for, even if the artist is popular af
BLACKLIST = ["black-metal", "bluegrass", "death-metal", "country", "heavy-metal", "metal", "alternative country"]




def get_song_rec_from_seeds(sp, songbank):
    while True:

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
        recs = musicscraper.get_track_recs(sp, seeds)
        if not recs:
            continue

        ## Move used seed(s) to used list in songbank
        songbank['used'] += seeds

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



############################################################# START MAIN CODE BLOCK ##########################################################
def lambda_handler(event, context):
    print("DEBUG: starting lambda_handler beginning function", event)

    ## Load songbank file
    songbank_json = s3Handler.read_file()d
    print("DEBUG: returned to main function from s3handler read_file")
    if not songbank_json:
        print("DEBUG: could not retrieve songbank json from S3, about to send error text")
        twilioHandler.send_error_message("Could not read songbank file from S3")
        sys.exit(1)
    current_refresh_token = songbank_json["refreshToken"]
    print("DEBUG: successfully retrieved saved refresh token from S3", current_refresh_token)

    ## Authenticate to Spotify
    print("DEBUG: about to call musicscraper auth spotify from main")
    sp, next_refresh_token = musicscraper.auth_spotify(current_refresh_token)
    print("DEBUG: back to main from musicscraper auth spotify call")
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
    songbank = musicscraper.load_songbank(sp, songbank_json)
    print("DEBUG: back to main from musicscraper load songbank call", songbank)
    if not songbank:
        print("DEBUG: did not return anything from load songbank call, about to send error text")
        twilioHandler.send_error_message("Cannot load songbank, aborting.")
        sys.exit(1)

    ## Load playlist information
    playlistTracks = playlistHandler.load_playlist(sp, songbank) 
    print("DEBUG: returned to main from playlisthandler load playlist call")
    if playlistTracks is False:
        print("DEBUG: could not retrieve playlisttracks from load playlist, about to send error text")
        twilioHandler.send_error_message("Cannot load playlist, aborting.")
        sys.exit(1)

    ## if no new songs need to be added, we're done!
    num_songs_to_add = int(os.environ["num_songs_in_playlist"]) - len(playlistTracks) 
    print("DEBUG: will attempt to add " + str(num_songs_to_add) + " songs to the playlist")
    if num_songs_to_add == 0:
        return {
            "status": "200",
            "body":   "success"
        }

    ## For each song to add, get a recommendation
    songs_to_add = []
    for _ in range(num_songs_to_add):
        print("DEBUG: about to get song rec from seeds")
        new_song_id, songbank = get_song_rec_from_seeds(sp, songbank)
        songs_to_add.append(new_song_id)
    print("DEBUG: finished collecting song recs", songs_to_add)

    ## Add new songs to songbank and write data to S3 for next time
    ## update Spotify refresh token for next invocation
    print("DEBUG: about to call musicscraper save songbank to S3")
    if not musicscraper.save_songbank(songbank, songs_to_add, next_refresh_token):
        print("DEBUG: could not save songbank to s3, about to send error text")
        twilioHandler.send_error_message("Could not save songbank to S3")
        sys.exit(1)
    print("DEBUG: successfully saved songbank to S3")

    ## Add recommended songs to Spotify playlist
    print("DEBUG: about to call playlisthandler to update playlist in Spotify")
    if not playlistHandler.save_playlist(sp, songbank['playlistId'], songs_to_add):
        print("DEBUG: could not save Spotify playlist, about to send error text")
        twilioHandler.send_error_message("Updated songbank with new content but could not push to playlist")
        sys.exit(1)


    ## All done!
    print("DEBUG: successfully completed TMF iteration, about to send success text")
    twilioHandler.send_completed_message()
    return {
        "status": "200",
        "body": "success"
    }



#print(lambda_handler("", ""))
