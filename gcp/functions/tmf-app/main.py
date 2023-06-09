## Main application flow

import os, base64, json
import musicQueryHandler, playlistHandler, twilioHandler, storageHandler, songbankHandler, tokenAuthHandler

## Terraform bools not capitalized unlike Python
DEBUG = True if os.environ["debug"] == "true" else False


############################################################# START MAIN CODE BLOCK ##########################################################
def main(event_data, _):
    if DEBUG: print("DEBUG: starting tmf app function")

    ## PubSub message has b64-encoded 'data' field of bytes
    ## Decode b64, convert to UTF-8 string, and create Python dict
    try:
        event = json.loads(base64.b64decode(event_data["data"]).decode("utf-8"))
        if DEBUG: print(f"DEBUG: event {event}")
    except Exception as e:
        if DEBUG: print(f"DEBUG: error reading pubsub input: {e}")
        return

    params = event
    user_number = params["user_number"]

    ## If user only wants seed info, don't update playlist, but need to load playlist and songbank
    if "seeds" in params:
        params["keep"] = True

    ## Make sure internet connectivity is working
    if not storageHandler.test_network_connectivity(DEBUG):
        if DEBUG: print("DEBUG: no network connectivity, about to send error text")
        twilioHandler.send_error_message(user_number, "TMF has no Internet connectivity, aborting.")
        return

    ## Load songbank file
    songbank_json = storageHandler.read_file(DEBUG)
    ## Check explicitly for False since empty JSON is also not True
    if songbank_json is False:
        if DEBUG: print("DEBUG: could not retrieve songbank json from Storage, about to send error text")
        twilioHandler.send_error_message(user_number, "Could not read songbank file from Cloud Storage, aborting.")
        return


    ## Retrieve and decrypt refresh token data
    refresh_token = os.environ["spotify_refresh_token"]
    if not refresh_token:
        if DEBUG: print("DEBUG: could not retrieve saved Spotify refresh token, about to send error text")
        twilioHandler.send_error_message(user_number, "Did not find expected env variable Spotify refresh token")
        return


    ## Authenticate to Spotify
    sp = tokenAuthHandler.auth_spotify(DEBUG, refresh_token)
    if not sp:
        if DEBUG: print("DEBUG: could not retrieve api client object from auth spotify call, about to send error text")
        twilioHandler.send_error_message(user_number, "Could not create API client with Spotify token")
        return


    ## Initialize Songbank
    ## API client needed to create playlist if first time
    songbank = songbankHandler.load_songbank(DEBUG, sp, songbank_json, params)
    if not songbank:
        if DEBUG: print("DEBUG: did not return anything from load songbank call, about to send error text")
        twilioHandler.send_error_message(user_number, "Cannot load songbank, aborting.")
        return


    ## Load playlist information, reset if user requested
    playlistTracks = playlistHandler.load_playlist(DEBUG, sp, songbank, params) 
    ## Check explicitly for False since empty list is also not True
    if playlistTracks is False:
        if DEBUG: print("DEBUG: could not retrieve tracks from playlist, about to send error text")
        twilioHandler.send_error_message(user_number, "Cannot load playlist, aborting.")
        return


    ## Check if user just wants song seed info
    if "seeds" in params:
        track, seeds = songbankHandler.get_seeds_for_track(DEBUG, playlistTracks, params["seeds"])
        ## All done!
        if DEBUG: print("DEBUG: seed info gathered, texting user song gen info")
        twilioHandler.send_completed_message(user_number, "Seeds of '" + track + "': " + ", ".join(seeds))
        return


    ## If user wants music, get appropriate number of song recommendations
    num_songs_to_add = int(os.environ["num_songs_in_playlist"]) - len(playlistTracks)
    if "size" in params:
        num_songs_to_add = int(params["size"]) - len(playlistTracks) 
    if DEBUG: print("DEBUG: will attempt to add " + str(num_songs_to_add) + " songs to the playlist")

    songs_to_add, songbank = musicQueryHandler.get_song_recs_from_seeds(DEBUG, sp, songbank, params, num_songs_to_add)
    if DEBUG: print("DEBUG: finished collecting song recs")


    ## Add new songs to songbank and write data to S3 for next time
    ## Save Spotify refresh token for next invocation
    if not songbankHandler.save_songbank(DEBUG, songbank, songs_to_add):
        if DEBUG: print("DEBUG: could not save songbank to storage, about to send error text")
        twilioHandler.send_error_message(user_number, "Could not save songbank to Cloud Storage")
        return


    ## Add recommended songs to Spotify playlist
    if not playlistHandler.save_playlist(DEBUG, sp, songbank["playlistId"], songs_to_add):
        if DEBUG: print("DEBUG: could not save Spotify playlist for user, about to send error text")
        twilioHandler.send_error_message(user_number, "Updated songbank with new content but could not push to playlist")
        return


    ## All done!
    if num_songs_to_add == 0:
        if DEBUG: print("DEBUG: no tracks to add to playlist, texting user TMF has nothing to do")
        twilioHandler.send_completed_message(user_number, "No tracks to update this time!")
    elif num_songs_to_add < 0:
        if DEBUG: print("DEBUG: user tried to keep playlist but decrease size, texting user that TMF can't tell which songs to remove and will not do anything")
        twilioHandler.send_completed_message(user_number, "Sorry, but I can't deliver the expected smaller size while keeping all current songs! Please try again.")
    elif num_songs_to_add != len(songs_to_add):
        if DEBUG: print("DEBUG: fairly successfully completed TMF iteration, about to send success text")
        twilioHandler.send_completed_message(user_number, "Here are " + str(len(songs_to_add)) + "/" + str(num_songs_to_add) + " songs, the desired number could not be generated within the allotted attempts")
    else:
        if DEBUG: print("DEBUG: successfully completed TMF iteration, about to send success text")
        twilioHandler.send_completed_message(user_number, "Enjoy your new " + str(num_songs_to_add) + " songs :)")
    return