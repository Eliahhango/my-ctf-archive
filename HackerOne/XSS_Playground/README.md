# XSS Playground

## Overview

This directory contains the local materials and manual walkthrough for the `XSS Playground by zseano` challenge from `Hacker101 / HackerOne CTF`. Although the theme suggests XSS, the actual flag path in this instance comes from inspecting the shipped JavaScript and discovering that the frontend contains both a hidden action and the custom header needed to authorize it.

This makes the challenge a very strong example of a broader web-security lesson: public JavaScript is not a safe place to hide secrets, internal features, or authorization material.

## Challenge Profile

- Challenge: `XSS Playground by zseano`
- Category: `Web`
- Collection: `HackerOne`
- Event or Platform: `Hacker101 / HackerOne CTF`

## Directory Contents

- `xss_playground_poc.sh`

## First Commands To Run

This folder does not include original challenge files. Follow the walkthrough the same way you would read a public writeup: understand the target behavior first, then reproduce each manual step against a fresh instance until the flag is visible.

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/XSS_Playground"
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

## What Makes The Challenge Interesting

The page looks like an XSS sandbox, and the JavaScript really does contain DOM-based XSS material. But the direct flag path is even simpler: reading `custom.js` reveals:

- a hidden function named `retrieveEmail()`
- a protected endpoint:
  `/api/action.php?act=getemail`
- a hardcoded custom header:
  `X-SAFEPROTECTION: enNlYW5vb2Zjb3Vyc2U=`

Once those are known, the protected endpoint can be called directly.

## Why This Is A Security Failure

If a backend relies on a custom header for authorization, but the frontend JavaScript hardcodes that same header value, then the protection is not meaningful. Any user can read the JavaScript, copy the header, and reproduce the request outside the browser.

This is conceptually similar to embedding API keys, role flags, or privileged routes in public client code and assuming users will not look.

## Manual Analysis Workflow

First inspect the main page:

```bash
curl -s 'https://b36e6ab066d9e8363822741a849e23ff.ctf.hacker101.com/' | sed -n '1,220p'
```

That reveals which JavaScript files are loaded.

Then read the custom script:

```bash
curl -s 'https://b36e6ab066d9e8363822741a849e23ff.ctf.hacker101.com/custom.js'
```

That is where the hidden endpoint and header value become visible.

Finally, call the endpoint directly:

```bash
curl -s 'https://b36e6ab066d9e8363822741a849e23ff.ctf.hacker101.com/api/action.php?act=getemail' \
  -H 'X-SAFEPROTECTION: enNlYW5vb2Zjb3Vyc2U='
```

The response includes both the email and the flag.

## The XSS Angle

The challenge name is still meaningful. The JavaScript includes DOM-based XSS sinks, especially around URL hash handling and unsafe DOM writes. In a real engagement, an attacker could combine that with the hidden `retrieveEmail()` capability to exfiltrate the same protected data in a victim’s browser context.

For the actual flag solve, however, XSS is not even required. Source inspection alone is enough.

That is part of what makes the challenge educational: the highest-value bug path is not always the one suggested by the title.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/XSS_Playground"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `^FLAG^71c17f768754bd8342cd0cdc77ce5085e2d8b8671d75e04a03907571366cb90f$`

## Study Notes

This challenge is worth revisiting if you are studying frontend trust boundaries, hidden feature discovery, and client-side secret exposure. It is a good reminder that before building a payload, it is often worth reading the JavaScript carefully. Sometimes the application has already handed you the secret path in plain sight.
