## Main application flow

import os, json
import musicQueryHandler, playlistHandler, twilioHandler, s3Handler, songbankHandler, tokenAuthHandler

## Terraform bools not capitalized unlike Python
DEBUG = True if os.environ["debug"] == "true" else False


############################################################# START MAIN CODE BLOCK ##########################################################
def lambda_handler(event, _):
    if DEBUG: print("DEBUG: starting lambda_handler beginning function", event)
    params = event

    ## Make sure internet connectivity is working
    if not s3Handler.test_network_connectivity(DEBUG):
        if DEBUG: print("DEBUG: no network connectivity, about to send error text")
        twilioHandler.send_error_message("TMF has no Internet connectivity, aborting.")
        return

    ## Load songbank file
    songbank_json = s3Handler.read_file(DEBUG)
    ## Check explicitly for False since empty JSON is also not True
    if songbank_json is False:
        if DEBUG: print("DEBUG: could not retrieve songbank json from S3, about to send error text")
        twilioHandler.send_error_message("Could not read songbank file from S3, aborting.")
        return

    ## Retrieve and decrypt refresh token data from SSM Parameter Store
    current_refresh_token = tokenAuthHandler.retrieve_refresh_token(DEBUG)
    if not current_refresh_token:
        print("DEBUG: could not retrieve saved Spotify refresh token, about to send error text")
        twilioHandler.send_error_message("Could not retrieve Spotify refresh token from Parameter Store")
        return


    ## Authenticate to Spotify
    sp, next_refresh_token = tokenAuthHandler.auth_spotify(DEBUG, current_refresh_token)
    if not next_refresh_token:
        print("DEBUG: could not retrieve next refresh token from auth spotify, about to send error text")
        twilioHandler.send_error_message("Could not get new access token from Spotify")
        return
    if not sp:
        print("DEBUG: could not retrieve api client object from auth spotify call, about to send error text")
        twilioHandler.send_error_message("Could not create API client with Spotify token")
        return


    ## Initialize Songbank
    ## API client needed to create playlist if first time
    songbank = songbankHandler.load_songbank(DEBUG, sp, songbank_json, params)
    if not songbank:
        if DEBUG: print("DEBUG: did not return anything from load songbank call, about to send error text")
        twilioHandler.send_error_message("Cannot load songbank, aborting.")
        return


    ## Load playlist information, reset if user requested
    playlistTracks = playlistHandler.load_playlist(DEBUG, sp, songbank, params) 
    ## Check explicitly for False since empty list is also not True
    if playlistTracks is False:
        if DEBUG: print("DEBUG: could not retrieve tracks from playlist, about to send error text")
        twilioHandler.send_error_message("Cannot load playlist, aborting.")
        return


    ## get appropriate number of song recommendations
    num_songs_to_add = int(os.environ["num_songs_in_playlist"]) - len(playlistTracks)
    if "size" in params:
        num_songs_to_add = int(params["size"]) - len(playlistTracks) 
    if DEBUG: print("DEBUG: will attempt to add " + str(num_songs_to_add) + " songs to the playlist")

    songs_to_add, songbank = musicQueryHandler.get_song_recs_from_seeds(DEBUG, sp, songbank, params, num_songs_to_add)
    if DEBUG: print("DEBUG: finished collecting song recs")


    ## Add new songs to songbank and write data to S3 for next time
    ## Save Spotify refresh token for next invocation
    if not songbankHandler.save_songbank(DEBUG, songbank, songs_to_add, next_refresh_token):
        if DEBUG: print("DEBUG: could not save songbank to s3, about to send error text")
        twilioHandler.send_error_message("Could not save songbank to S3")
        return


    ## Add recommended songs to Spotify playlist
    if not playlistHandler.save_playlist(DEBUG, sp, songbank["playlistId"], songs_to_add):
        if DEBUG: print("DEBUG: could not save Spotify playlist, about to send error text")
        twilioHandler.send_error_message("Updated songbank with new content but could not push to playlist")
        return


    ## All done!
    if num_songs_to_add == 0:
        if DEBUG: print("DEBUG: no tracks to add to playlist, texting user TMF has nothing to do")
        twilioHandler.send_completed_message("No tracks to update this time!")
    elif num_songs_to_add < 0:
        if DEBUG: print("DEBUG: user tried to keep playlist but decrease size, texting user that TMF can't tell which songs to remove and will not do anything")
        twilioHandler.send_completed_message("Sorry, but I can't deliver the expected smaller size while keeping all current songs! Please try again.")
    elif num_songs_to_add != len(songs_to_add):
        if DEBUG: print("DEBUG: fairly successfully completed TMF iteration, about to send success text")
        twilioHandler.send_completed_message("Here are " + str(len(songs_to_add)) + "/" + str(num_songs_to_add) + " songs, the desired number could not be found")
    else:
        if DEBUG: print("DEBUG: successfully completed TMF iteration, about to send success text")
        twilioHandler.send_completed_message("Enjoy your new " + str(num_songs_to_add) + " songs :)")
    return {
        "status": "200",
        "body": "success"
    }