import threading
import socket
import webbrowser
import requests
import urllib.parse
import base64
import json
import sys

def authorize_twilify(client_id):
    scope = "user-top-read playlist-modify-private playlist-modify-public playlist-read-private playlist-read-collaborative"
    auth_url = "https://accounts.spotify.com/authorize?"
    auth_data = {
        "response_type": "code",
        "client_id": client_id,
        "scope": scope,
        "redirect_uri": "http://127.0.0.1"
    }
    auth_url += urllib.parse.urlencode(auth_data)
    webbrowser.open(auth_url)

## Result is a single element list where we will store the oauth code value produced by thread
def receive_oauth_code(result):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(("127.0.0.1", 80))
    s.listen(1)

    conn, _ = s.accept()
    data = conn.recv(1024).decode()
    code = urllib.parse.urlparse(data).query.split(" ")[0]
    if code.startswith("code="):
        result[0] = code[5:]
    else:
        conn.close()
        return

    conn.send(b"Spotify user authentication complete! Twilify will now deploy application via Terraform (you may close this window)")
    conn.close()


def get_refresh_token(auth_code, client_id, client_secret):
    token_url = "https://accounts.spotify.com/api/token"
    token_auth_header = base64.b64encode(bytes(f"{client_id}:{client_secret}", "utf-8")).decode("utf-8")
    token_data = {
        "grant_type": "authorization_code",
        "code": auth_code,
        "redirect_uri": "http://127.0.0.1" ## not used, but required for validating request
    }
    token_headers = {
        "Authorization": f"Basic {token_auth_header}",
        "Content-Type": "application/x-www-form-urlencoded"
    }
    r = requests.post(token_url, data=token_data, headers=token_headers)
    return json.loads(r.content.decode())["refresh_token"]



def main():
    if len(sys.argv) != 3:
        return

    code_value = [None] ## declare variable where we want to store the oauth code value
    t_server = threading.Thread(target=receive_oauth_code, args=[code_value])
    t_server.start()
    threading.Thread(target=authorize_twilify, args=[sys.argv[1]]).start()
    t_server.join()

    token_value = get_refresh_token(code_value[0], sys.argv[1], sys.argv[2])
    print(token_value)



if __name__ == "__main__":
    main()