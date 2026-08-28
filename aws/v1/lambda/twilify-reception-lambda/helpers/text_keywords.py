import re


def get_text_keywords(DEBUG, text):
    ## convert text to all lowercase first
    text = text.lower()

    if DEBUG: print(f"DEBUG: received SMS body: {text}")
    text_keywords = {}

    ## check to see if reset keyword included in text
    match = re.search(r"keep", text)
    if match is not None:
        if DEBUG: print("DEBUG: found keep keyword")
        text_keywords["keep"] = True

    ## check to see if size keyword included in text
    match = re.search(r"size\s+([0-9]+)", text)
    if match is not None:
        if DEBUG: print("DEBUG: found size keyword", match.group())
        text_keywords["size"] = match.group(1)

    ## check to see if happy keyword included in text
    match = re.search(r"happy", text)
    if match is not None and "sad" not in text_keywords:
        if DEBUG: print("DEBUG: found happy keyword")
        text_keywords["happy"] = True

    ## check to see if sad keyword included in text
    match = re.search(r"sad", text)
    if match is not None and "happy" not in text_keywords:
        if DEBUG: print("DEBUG: found sad keyword")
        text_keywords["sad"] = True
    
    ## check to see if tempo keyword included in text
    match = re.search(r"tempo\s+([0-9]+)", text)
    if match is not None:
        if DEBUG: print("DEBUG: found tempo keyword", match.group())
        text_keywords["tempo"] = match.group(1)
    
    ## check to see if instrumental keyword included in text
    match = re.search(r"instrumental", text)
    if match is not None:
        if DEBUG: print("DEBUG: found instrumental keyword")
        text_keywords["instrumental"] = True
    
    ## check to see if energy keyword included in text
    match = re.search(r"energy\s+(\w+)", text)
    if match is not None:
        if DEBUG: print(f"DEBUG: found energy keyword: {match.group()}")
        energy_type = match.group(1)
        if energy_type == "low":
            text_keywords["energy"] = "low"
        elif energy_type == "medium":
            text_keywords["energy"] = "medium"
        elif energy_type == "high":
            text_keywords["energy"] = "high"
        elif DEBUG: print("DEBUG: did not include valid energy type, ignoring")

    ## check to see if dance keyword included in text
    match = re.search(r"dance", text)
    if match is not None:
        if DEBUG: print("DEBUG: found dance keyword")
        text_keywords["dance"] = True

    ## check to see if overwrite keyword included in text
    match = re.search(r"overwrite", text)
    if match is not None:
        if DEBUG: print("DEBUG: found overwrite keyword")
        text_keywords["overwrite"] = True

    ## check to see if seeds keyword included in text
    match = re.search(r"seeds\s+([0-9]+)", text)
    if match is not None:
        if DEBUG: print("DEBUG: found seeds keyword", match.group())
        text_keywords["seeds"] = int(match.group(1))

    return text_keywords