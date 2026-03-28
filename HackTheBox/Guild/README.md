# Guild

## Overview

This directory contains the local materials and manual walkthrough for the `Guild` challenge on Hack The Box - CTF Try Out. The archived notes identify it as a `Easy` challenge. This README is written as a practical walkthrough so someone can open the folder, inspect the challenge files, understand the intended weakness, and reproduce the solve with commands that are easy to copy and run.

## Challenge Profile

- Challenge: `Guild`
- Category: `Web`
- Platform: `Hack The Box - CTF Try Out`
- Difficulty: `Easy`

## Directory Contents

- `Dockerfile`
- `build_docker.sh`
- `guild/`
- `guild_poc.sh`
- `web_guild.zip`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Guild"
ls -lah
unzip -l "web_guild.zip"
```

Useful first inspection commands:

```bash
sed -n '1,220p' 'Dockerfile'
sed -n '1,220p' 'build_docker.sh'
file 'web_guild.zip'
strings -n 5 'web_guild.zip' | head -200
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Walkthrough

Challenge: Guild
Platform: Hack The Box - CTF Try Out
Category: Web
Difficulty: Easy

### Scenario summary

The application asks normal users to wait for a "Guild Master" to verify them.
The flag is not visible to regular users, and the interesting app paths are spread
across profile sharing, password reset, and image verification.

Core concepts used in this solve:
1. Server-Side Template Injection (SSTI) in a shared profile page.
2. Predictable password-reset link generation using sha256(email).
3. A second SSTI sink inside EXIF metadata, reachable only after becoming admin.

### Real-world lesson

This is exactly the kind of "small issues chaining into a full compromise" flow
defenders underestimate:
- A "read-only" template injection leaks internal data.
- A weak reset-link design turns that leak into account takeover.
- An internal moderation/admin workflow becomes the privileged execution sink.

Why this challenge takes more than one request:
The first SSTI is filtered, so it is mainly useful for leaking data.
The second SSTI is unfiltered, but it sits behind admin-only functionality.
So the intended path is:
leak admin email -> generate reset token -> take admin -> abuse EXIF SSTI -> read flag

Usage:

Expected output:
HTB{...}

Challenge files used:
- web_guild.zip
- unpacked Flask source in ./guild/

Final flag recovered on this instance:
HTB{mult1pl3_lo0p5_mult1pl3_h0les_58d3764773e4f939ba8933b944b2ed4d}

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Guild"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `HTB{mult1pl3_lo0p5_mult1pl3_h0les_58d3764773e4f939ba8933b944b2ed4d}`

## Study Notes

This challenge is worth revisiting if you are practicing `Web` problems. Inspect the routes and source manually first, confirm the weakness yourself, and only then compare your reasoning against the archived solve notes.
