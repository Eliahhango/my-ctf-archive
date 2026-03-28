# Welcome

## Overview

This directory contains the local notes and manual walkthrough for the
`Welcome` challenge from `HackIT`. The provided string is Base64 and decodes
immediately into a readable flag-like message.

## Challenge Profile

- Challenge: `Welcome`
- Category: `Crypto`
- Platform: `HackIT`
- Points: `50`

## Directory Contents

- `challenge.txt`
- `welcome_poc.sh`

## First Commands To Run

Start with the archived challenge text in this folder.

```bash
cd "/home/eliah/Desktop/CTF/hackit/Welcome"
ls -lah
sed -n '1,120p' challenge.txt
```

Useful first inspection command:

```bash
bash ./welcome_poc.sh
```

## Walkthrough

Challenge Name: Welcome
Category: Crypto
Platform: HackIT
Points: 50

### Description

"My friend sent me this message, can you decipher it for me ?
R29Te1dlbGNvbWVfdG9fc2l0ZSF9"

Flag format: `GoH{flag}`

### Step 1: Recognize the encoding.

Important observations:

- The alphabet matches Base64-safe characters.
- This is a short beginner challenge, so lightweight encodings are the first
  thing to test.

### Step 2: Decode the string.

Manual command:

```bash
printf '%s' 'R29Te1dlbGNvbWVfdG9fc2l0ZSF9' | base64 -d
```

Recovered text:

`GoS{Welcome_to_site!}`

### Step 3: Adapt the wrapper to the stated flag format.

Manual command:

```bash
bash ./welcome_poc.sh
```

Recovered submission:

`GoH{Welcome_to_site!}`

### Why this works

The payload body is clearly `Welcome_to_site!`, and the challenge explicitly
states that accepted flags use the `GoH{...}` format. That makes the correct
submission:

`GoH{Welcome_to_site!}`

## Manual Reproduction Flow

```bash
cd "/home/eliah/Desktop/CTF/hackit/Welcome"
ls -lah
bash ./welcome_poc.sh
```

## Final Flag

`GoH{Welcome_to_site!}`
