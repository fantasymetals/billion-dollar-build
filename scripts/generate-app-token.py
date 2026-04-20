#!/usr/bin/env python3
"""Generate a GitHub App installation token from the private key PEM.

Usage:
    python generate-app-token.py <pem-file> <app-id> <installation-id>

Output:
    The installation token (printed to stdout).
"""

import sys
import time
import json
import urllib.request
import jwt

def main():
    if len(sys.argv) != 4:
        print("Usage: generate-app-token.py <pem-file> <app-id> <installation-id>", file=sys.stderr)
        sys.exit(1)

    pem_file = sys.argv[1]
    app_id = sys.argv[2]
    installation_id = sys.argv[3]

    # Read private key
    with open(pem_file, 'r') as f:
        private_key = f.read()

    # Generate JWT (valid for 10 minutes max per GitHub docs)
    now = int(time.time())
    payload = {
        "iat": now - 60,        # Issued at (60s in the past to account for clock drift)
        "exp": now + (10 * 60), # Expires in 10 minutes
        "iss": app_id           # Issuer = App ID
    }

    encoded_jwt = jwt.encode(payload, private_key, algorithm="RS256")
    print(f"JWT generated (expires in 10 min)", file=sys.stderr)

    # Exchange JWT for installation token
    url = f"https://api.github.com/app/installations/{installation_id}/access_tokens"
    req = urllib.request.Request(url, data=b'{}', headers={
        "Authorization": f"Bearer {encoded_jwt}",
        "Accept": "application/vnd.github+json",
        "Content-Type": "application/json",
        "X-GitHub-Api-Version": "2022-11-28"
    })

    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read())
            token = data["token"]
            expires = data["expires_at"]
            print(f"Installation token generated (expires: {expires})", file=sys.stderr)
            print(token)  # Token to stdout for piping
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"ERROR {e.code}: {body}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
