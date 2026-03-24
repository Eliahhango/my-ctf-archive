#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: Postbook
# Platform: Hacker101 CTF / HackerOne
# Category: Web
#
# Target:
# https://788b07c6bc7cfcdfb6348b1bbd38e2b9.ctf.hacker101.com/
#
# Description:
# Postbook is a small blogging platform with public and private posts.
# At first glance it looks like a normal sign up / sign in application, but the
# core weakness is in how it represents authentication state.
#
# Core lesson:
# Never trust client-controlled authentication identifiers.
#
# Real-world analogy:
# Imagine a website that stores a cookie saying:
#   role=admin
# or:
#   user_id=1
# and assumes that because the browser sent it, the value must be legitimate.
#
# That is equivalent to letting users print their own employee badge at home and
# trusting it at the front desk.
#
# If the server does not sign, encrypt, or validate the session securely, an
# attacker can simply forge a more privileged identity.
#
# What we observed during analysis:
# 1. We created a normal account and logged in.
# 2. The server set a cookie named "id".
# 3. For a newly created account with user_id = 4, the cookie value was:
#      a87ff679a2f3e71d9181a67b7542122c
# 4. That value is md5("4").
#
# That means the app is not using a secure random session token.
# It is using a predictable transformation of the numeric user ID.
#
# Why this is fatal:
# If the admin user is user_id = 1, then the attacker can compute:
#   md5("1") = c4ca4238a0b923820dcc509a6f75849b
#
# and place that value in the browser cookie manually.
#
# The server then treats the attacker as admin.
#
# Step 1: Confirm the application routes.
# Manual observation:
# The app uses links like:
#   index.php?page=sign_in.php
#   index.php?page=sign_up.php
#   index.php?page=home.php
#
# Why this matters:
# It tells us the app is driven by a page parameter and likely relies on
# server-side includes or route dispatch logic inside index.php.
#
# Step 2: Create a normal account.
# Manual idea:
# Sign up any new user and then sign in.
#
# Why this matters:
# Logging in as a normal user lets us observe the authentication cookie that the
# application gives to legitimate users.
#
# Step 3: Inspect the cookie.
# Important discovery:
# For one test account, the cookie "id" matched md5("4"), where 4 was the
# visible numeric user_id in the page source.
#
# Why this matters:
# This proves the server trusts a predictable, client-forgeable identifier.
#
# Step 4: Forge the admin cookie.
# Manual command concept:
# Compute md5("1") and set it as the "id" cookie.
#
# Admin cookie:
# c4ca4238a0b923820dcc509a6f75849b
#
# Why this works:
# The server appears to look up the current user purely from that cookie value.
# Since MD5 is deterministic and user IDs are guessable, admin impersonation is
# trivial.
#
# Real-world lesson:
# Hashing a predictable identifier does not make it secure.
# If the input space is tiny and guessable, the output is just as guessable.
#
# Step 5: Request the admin home page.
# Manual result:
# Visiting:
#   index.php?page=home.php
# while sending the forged admin cookie reveals the admin-only content and the
# Hacker101 flag token in the HTML.
#
# Recovered flag:
# ^FLAG^8d165ea9ed892300feec163f3f51c1e75aacbf9762e642f72269765335401961$FLAG$
#
# Extra observations:
# - The forged admin session also exposed the admin account settings page.
# - It also exposed the admin private post.
# - This confirms that the cookie controls full authorization, not just display.
#
# Defensive takeaway:
# A secure design should use:
# - random, high-entropy session identifiers
# - server-side session storage or signed tokens
# - authorization checks tied to trusted server state
# - session invalidation and integrity protection
#
# It should never derive an auth token directly from a predictable value like a
# user ID.

python3 - <<'PY'
import hashlib
import re

import requests

base = "https://788b07c6bc7cfcdfb6348b1bbd38e2b9.ctf.hacker101.com/index.php"
admin_cookie = hashlib.md5(b"1").hexdigest()

s = requests.Session()
s.cookies.set(
    "id",
    admin_cookie,
    domain="788b07c6bc7cfcdfb6348b1bbd38e2b9.ctf.hacker101.com",
    path="/",
)

r = s.get(base + "?page=home.php", timeout=15)
match = re.search(r"\^FLAG\^[^\s<]+\$FLAG\$", r.text)

if not match:
    raise SystemExit("Flag not found in admin home page response.")

print(match.group(0))
PY
