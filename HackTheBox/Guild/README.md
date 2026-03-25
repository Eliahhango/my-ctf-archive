# Guild

## Overview

This directory contains the local materials and saved solve workflow for the `Guild` challenge on Hack The Box - CTF Try Out. The archived notes identify it as a `Easy` challenge. This README is written as a practical walkthrough so someone can open the folder, inspect the challenge files, understand the intended weakness, and reproduce the solve with commands that are easy to copy and run.

## Challenge Profile

- Challenge: `Guild`
- Category: `Web`
- Platform: `Hack The Box - CTF Try Out`
- Difficulty: `Easy`
- Saved PoC: `guild_poc.sh`

## Directory Contents

- `Dockerfile`
- `build_docker.sh`
- `guild/`
- `guild_poc.sh`
- `web_guild.zip`

## First Commands To Run

Begin with a short inventory so you can see the original challenge archive, any extracted directories, and the solve script saved in this folder.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Guild"
ls -lah
```

If you want to verify what was originally provided by Hack The Box, inspect the archive contents before extracting or re-extracting them.

```bash
unzip -l "web_guild.zip"
```

Read the top of the PoC first. The comments there summarize the exact idea used during the solve and usually explain the bug, leak, algorithm, or reversing trick directly.

```bash
sed -n "1,220p" "guild_poc.sh"
```

Run the PoC after reviewing the notes.

```bash
chmod +x "guild_poc.sh"
./guild_poc.sh
```

If the script targets a spawned remote service, you can usually point it at a fresh instance by supplying a host and port.

```bash
./guild_poc.sh <HOST> <PORT>
```

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
bash guild_poc.sh
bash guild_poc.sh http://154.57.164.77:31927

Expected output:
HTB{...}

Challenge files used:
- web_guild.zip
- unpacked Flask source in ./guild/

Final flag recovered on this instance:
HTB{mult1pl3_lo0p5_mult1pl3_h0les_58d3764773e4f939ba8933b944b2ed4d}

## Reproduction Commands

Use the following command sequence if you want a short and reliable path from opening the folder to reproducing the saved solve.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Guild"
unzip -l "web_guild.zip"
sed -n "1,220p" "guild_poc.sh"
bash "guild_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are practicing `Web` problems. The saved PoC is meant to be the fast path, but the better learning path is to inspect the provided files yourself first, confirm the weakness manually, and then compare your reasoning with the script comments and implementation.
