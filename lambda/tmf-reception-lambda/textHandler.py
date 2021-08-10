import re

def parse_text(DEBUG, body):
    if DEBUG: print("DEBUG: received message " + str(body))
    playlist_params = {}

    ## check to see if reset keyword included in text
    match = re.search(r"reset", body)
    if match is not None:
        if DEBUG: print("DEBUG: found reset keyword")
        playlist_params["reset"] = True

    ## check to see if size keyword included in text
    match = re.search(r"size [0-9]+", body)
    if match is not None:
        if DEBUG: print("DEBUG: found size keyword")
        playlist_params["size"] = int(match.group().split(" ")[1])

    ## check to see if keyword keyword included in text
    match = re.search(r"keyword \w+", body)
    if match is not None:
        if DEBUG: print("DEBUG: found keyword keyword")
        playlist_params["keyword"] = match.group().split(" ")[1]
    
    return playlist_params