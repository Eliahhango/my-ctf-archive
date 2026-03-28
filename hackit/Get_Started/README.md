# Get Started

## Overview

This directory contains the local notes and manual walkthrough for the `Get
Started` challenge from `HackIT`. The challenge is a simple encoding task: the
provided text is Base64 and decodes immediately to a flag-like string.

## Challenge Profile

- Challenge: `Get Started`
- Category: `Crypto`
- Platform: `HackIT`
- Points: `50`

## Directory Contents

- `challenge.txt`
- `get_started_poc.sh`

## First Commands To Run

Start with the archived challenge text in this folder.

```bash
cd "/home/eliah/Desktop/CTF/hackit/Get_Started"
ls -lah
sed -n '1,120p' challenge.txt
```

Useful first inspection command:

```bash
bash ./get_started_poc.sh
```

## Writeup Flow

This README follows the same solve structure as the rest of the workspace:
start from the provided encoded text, identify the encoding, verify it with a
reproducible command, and stop only when the final submission flag is visible.

When you work through it, keep asking four questions:

1. What exact string did the challenge give me?
2. Does it look like a known encoding format?
3. What does it decode to?
4. Does the decoded wrapper match the platform's stated submission format?

## Walkthrough

Challenge Name: Get Started
Category: Crypto
Platform: HackIT
Points: 50

### Description

"My friend sent me this message, can you decipher it for me ?
R29Te1dlbGNvbWVfdG9fc2l0ZSF9"

Flag format: `GoH{flag}`

### Step 1: Inspect the encoded string.

Manual command:

```bash
sed -n '1,120p' challenge.txt
```

Important observations:

- The string uses only Base64-safe characters.
- Its length is consistent with a short encoded message.
- The challenge is introductory, so a common encoding is more likely than a
  complex cipher.

Why this matters:

Base64 is one of the first things to test in beginner crypto or warm-up
challenges.

### Step 2: Decode the string as Base64.

Manual command:

```bash
printf '%s' 'R29Te1dlbGNvbWVfdG9fc2l0ZSF9' | base64 -d
```

Recovered text:

`GoS{Welcome_to_site!}`

Why this matters:

The payload is clearly readable after decoding, which confirms that Base64 is
the correct transformation.

### Step 3: Normalize the wrapper to the stated platform format.

Manual command:

```bash
bash ./get_started_poc.sh
```

What the script does:

- Base64-decodes the given string
- extracts the body inside the braces
- rebuilds the answer using the stated `GoH{...}` format

Accepted submission:

`GoH{Welcome_to_site!}`

### Why this works

The decoded text uses `GoS{...}`, but the challenge explicitly states that the
flag format is `GoH{flag}`. In practice, that means the message body is the
important part and the wrapper must be adapted to the platform's accepted
format.

This is the same kind of wrapper mismatch we already saw in the previous
HackIT challenge.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path.

```bash
cd "/home/eliah/Desktop/CTF/hackit/Get_Started"
ls -lah
bash ./get_started_poc.sh
```

## Final Flag

Following the manual path in this README leads to:
`GoH{Welcome_to_site!}`

## Study Notes

This is a good reminder to test lightweight encodings early and to pay
attention to any explicitly stated flag format, even when the decoded text
looks almost correct on its own.
