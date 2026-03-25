# Micro-CMS 2

## Overview

This directory contains the local materials and saved solve workflow for the `Micro-CMS (next level after the first Micro-CMS instance)` challenge from `Hacker101 / HackerOne CTF`. The goal of this README is to make the folder immediately useful to someone reviewing the archive later: what the challenge was about, what files matter, how the solve works at a high level, and which commands to run first.

## Challenge Profile

- Challenge: `Micro-CMS (next level after the first Micro-CMS instance)`
- Category: `Web`
- Collection: `HackerOne`
- Event or Platform: `Hacker101 / HackerOne CTF`
- Saved PoC: `micro_cms_2_poc.sh`

## Directory Contents

- `micro_cms_2_poc.sh`

## First Commands To Run

Start by listing the directory and reading the saved proof-of-concept script. In this archive, the PoC comments are treated as the primary solve notes and usually contain the most important reasoning.

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/Micro-CMS_2"
ls -lah
sed -n "1,220p" "micro_cms_2_poc.sh"
```

If you want to execute the saved solve directly:

```bash
chmod +x "micro_cms_2_poc.sh"
./micro_cms_2_poc.sh
```

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

### One-shot behavior

Running this script creates a disposable page with the image payload,
fetches the rendered page, and prints the flag directly.

## Reproduction Commands

Use this sequence if you want the shortest path from opening the folder to reproducing the saved solve:

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/Micro-CMS_2"
sed -n "1,220p" "micro_cms_2_poc.sh"
bash "micro_cms_2_poc.sh"
```

## Study Notes

This folder is best used as a practical study reference for `Web`-style problems. The fastest path is to run the PoC, but the more valuable path is to read the solve notes first, inspect the local files yourself, and then compare your reasoning to the saved exploit or script.
