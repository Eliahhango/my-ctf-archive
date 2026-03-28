# Micro-CMS 2

## Overview

This directory contains the local materials and manual walkthrough for the `Micro-CMS (next level after the first Micro-CMS instance)` challenge from `Hacker101 / HackerOne CTF`. The goal of this README is to make the folder immediately useful to someone reviewing the archive later: what the challenge was about, what files matter, how the solve works at a high level, and which commands to run first.

## Challenge Profile

- Challenge: `Micro-CMS (next level after the first Micro-CMS instance)`
- Category: `Web`
- Collection: `HackerOne`
- Event or Platform: `Hacker101 / HackerOne CTF`

## Directory Contents

- `micro_cms_2_poc.sh`

## First Commands To Run

This folder does not include original challenge files. Follow the walkthrough the same way you would read a public writeup: understand the target behavior first, then reproduce each manual step against a fresh instance until the flag is visible.

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/Micro-CMS_2"
ls -lah
printf 'Follow the manual walkthrough below against the live service.\n'
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Walkthrough

Challenge: Micro-CMS (next level after the first Micro-CMS instance)
Platform: Hacker101 / HackerOne CTF
Category: Web

Target:
https://485e7c84a8bab02b6bb7bbf261539e34.ctf.hacker101.com/

### What this challenge teaches

Input filtering that tries to "scrub" dangerous HTML by replacing words or
tweaking obvious patterns is brittle. If the application still allows some
HTML tags through, those surviving tags can become carriers for sensitive
server-side data such as a hidden flag attribute.

### Real-world analogy

This is like a building guard who only confiscates items named "knife" but
still allows a sharpened screwdriver through. The defense is focused on a
narrow pattern instead of controlling the real danger: untrusted HTML being
rendered in the browser.

Observed behavior in this level:
1. The CMS supports page creation and editing without authentication.
2. Raw script tags are not removed safely; they are rewritten into tags like
<scrubbed>, which shows the app is doing ad-hoc string replacement.
3. A markdown link with javascript: becomes "javascrubbed:", another sign of
weak keyword-based filtering.
4. Most importantly, an HTML image tag survives rendering:
<img src=x onerror=alert(1)>
5. When the image tag survives, the rendered page includes a server-injected
attribute named flag on that img element.

### Why this matters

Once a server renders attacker-controlled HTML, even if it "sanitizes" some
obvious payloads, the surviving markup can still expose secrets or become an
XSS gadget. The right defense is proper escaping or a well-tested sanitizer,
not hand-written replacements.

Manual solve steps:

### Step 1: Create a page containing an HTML image payload.

Command:
curl -i -sS -X POST 'https://485e7c84a8bab02b6bb7bbf261539e34.ctf.hacker101.com/page/create' \
--data-urlencode 'title=test3' \
--data-urlencode 'body=<img src=x onerror=alert(1)>'
Reason:
The image tag is one of the payloads that survives the markdown/rendering
pipeline in this level.

### Step 2: Follow the redirect to the created page.

Command:
curl -sS 'https://485e7c84a8bab02b6bb7bbf261539e34.ctf.hacker101.com/page/14'
Reason:
The server responds with a Location header like /page/14 after creation.
Viewing that page reveals the final rendered HTML.

### Step 3: Extract the injected flag attribute.

Command:
curl -sS 'https://485e7c84a8bab02b6bb7bbf261539e34.ctf.hacker101.com/page/14' | grep -o 'flag=\"[^\"]*\"'
Reason:
The page contains:
<img src=x flag="^FLAG^...$FLAG$" onerror=alert(1)>
so the flag can be pulled straight from the HTML source.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/Micro-CMS_2"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `^FLAG^b688020e0f646d6a20457df946434b395d1ac1f9b60b21ea582e5a075cc2b2f6$FLAG$`

## Study Notes

This folder is best used as a practical study reference for `Web`-style problems. Follow the HTTP requests and source analysis manually first, then compare your reasoning against the archived solve notes only if needed.
