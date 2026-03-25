# Micro-CMS

## Overview

This directory contains the local materials and manual walkthrough for the `Micro-CMS` challenge from `Hacker101 CTF / HackerOne`. The goal of this README is to make the folder immediately useful to someone reviewing the archive later: what the challenge was about, what files matter, how the solve works at a high level, and which commands to run first.

## Challenge Profile

- Challenge: `Micro-CMS`
- Category: `Web`
- Collection: `HackerOne`
- Event or Platform: `Hacker101 CTF / HackerOne`

## Directory Contents

- `micro_cms_poc.sh`

## First Commands To Run

This folder does not include original challenge files. Start by reading the challenge description and the manual walkthrough below, then connect to a fresh challenge instance and reproduce the steps one by one.

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/Micro-CMS"
ls -lah
printf 'Follow the manual walkthrough below against the live service.\n'
```

## Walkthrough

Challenge Name: Micro-CMS
Platform: Hacker101 CTF / HackerOne
Category: Web

Target:
https://375d9d90f37dd7436583b6e75dbe0550.ctf.hacker101.com/

### Description

Micro-CMS is a tiny content-management application that lets us:
- view pages
- create pages
- edit pages
- render user content as Markdown

At first glance it looks harmless, but the page renderer tries to "sanitize"
dangerous markup in a fragile, ad-hoc way.

### Core lesson

"Scripts are not allowed" is not a real security property unless the HTML
sanitization is done comprehensively and correctly.

### Real-world analogy

Imagine a building guard who only checks whether someone is carrying a pistol,
but ignores knives, fake IDs, or hidden tools.
That is not a real security model. It is a narrow filter pretending to be a
complete defense.

In web applications, partial HTML filtering often fails the same way:
- it strips some tags
- it rewrites some words
- but it still lets active or attacker-controlled HTML survive

### Step 1: Inspect the visible routes.

Manual observation:
The homepage links to:
- /page/1
- /page/2
- /page/create

Each page also links to:
- /page/edit/<id>

### Why this matters

It tells us we have full authoring and editing functionality available without
needing authentication, which is a strong hint that user-controlled HTML or
Markdown may be the intended attack surface.

### Step 2: Test how Markdown is rendered.

Manual idea:
Create pages with different inputs:
- plain text
- Markdown image syntax
- javascript: links
- raw HTML

### Why this matters

We want to understand not just whether input is accepted, but how it is
transformed on output.

Security rule:
Stored input + output transformation = where many XSS bugs live.

### Step 3: Observe the filter behavior.

Important results from live testing:
- Markdown images are rendered into <img> tags
- javascript: URLs are rewritten to javascrubbed:
- <script> tags are rewritten to <scrubbed>
- but raw <img ...> HTML still survives in the page output

### Why this matters

This tells us the sanitization is blacklisting a few obvious cases rather than
safely parsing and re-serializing trusted HTML.

That is dangerous because HTML is large and complex:
blocking one or two patterns rarely blocks all exploitation paths.

### Step 4: Use a raw HTML payload with an image tag.

Payload used:
<script>alert(1)</script><img src=x onerror=alert(1)>

Why this payload is useful:
- the script tag helps us observe the sanitizer reaction
- the image tag tests whether event-bearing HTML attributes survive

Result returned by the server:
<scrubbed>alert(1)</scrubbed>
<p><img src=x flag="^FLAG^...$FLAG$" onerror=alert(1)></p>

Key insight:
The server itself inserted the Hacker101 flag into a custom "flag" attribute
on the rendered <img> element.

That means we do not need a browser pop-up, an admin bot, or JavaScript
execution to recover the flag. The flag is already present in the response.

### Real-world lesson

A broken sanitizer can create surprising "secondary leaks."
Even if an application tries to block script execution, it may still expose
sensitive data in attacker-controlled markup, attributes, or DOM structure.

### Step 5: Extract the flag from the response HTML.

Manual command concept:
- POST the payload to /page/create
- follow the redirect to the new page
- search the returned HTML for the pattern:
^FLAG^...$FLAG$

### Why this works

The challenge back-end places the flag directly into the generated HTML once
the dangerous input reaches the vulnerable code path.

### Flag obtained

^FLAG^b688020e0f646d6a20457df946434b395d1ac1f9b60b21ea582e5a075cc2b2f6$FLAG$

Defensive takeaway:
Safe HTML handling should use:
- a real allowlist-based HTML sanitizer
- context-aware escaping
- strict Markdown rendering rules
- no custom regex-style sanitization for active content

Filtering by replacing words like "script" or "javascript" is brittle and
does not provide reliable protection.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/Micro-CMS"
ls -lah
```

## Study Notes

This folder is best used as a practical study reference for `Web`-style problems. Follow the HTTP requests and source analysis manually first, then compare your reasoning against the archived solve notes only if needed.
