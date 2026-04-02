# chained

## Overview

This directory contains the local notes and manual walkthrough for the
`chained` challenge from `cpl.ctfzone`.

The ciphertext is a printable string with a few layers:

1. strip the non-Base64 separators
2. Base64-decode the cleaned payload
3. use the flag prefix `snf{` as a crib to recover a short repeating XOR key
4. keep the printable payload that emerges from the decrypted stream

## Challenge Profile

- Challenge: `chained`
- Category: `crypto`
- Platform: `cpl.ctfzone`
- Difficulty: `MEDIUM`
- Points: `300`
- Author: `erickalex`

## Directory Contents

- `challenge.txt`
- `chained_poc.sh`

## First Commands To Run

```bash
cd "/home/eliah/Desktop/CTF/cpl.ctfzone/chained"
ls -lah
sed -n '1,120p' challenge.txt
```

Useful first inspection command:

```bash
bash ./chained_poc.sh
```

## Writeup Flow

This challenge is easiest to approach as a chain of lightweight transforms.
The raw text looks noisy, but the printable alphabet is a clue that the first
layer is an encoding rather than a heavy cryptosystem.

When solving, keep asking:

1. Which characters are separators or noise?
2. What clean encoding appears after removing them?
3. Does the decoded layer look like a stream cipher or XOR layer?
4. Does the flag prefix help recover the remaining key material?

## Walkthrough

### Step 1: Normalize the visible ciphertext

The challenge string contains Base64-safe characters mixed with separators.
Removing the separators gives a clean Base64 payload that can be decoded.

### Step 2: Decode the cleaned payload

The decoded bytes are not immediately readable, which points to another layer.

### Step 3: Use the flag prefix as a crib

The screenshot shows the flag format `snf{somethinghere}`. Using `snf{` as the
crib recovers a 4-byte repeating XOR key for the decoded layer.

### Step 4: Read the printable stream

Decrypting with that key exposes a printable stream whose visible body is:

`QT9MjuaOsjsxlqFMtTYuzrv`

That leads to the final candidate:

`snf{QT9MjuaOsjsxlqFMtTYuzrv}`

## Final Flag

`snf{QT9MjuaOsjsxlqFMtTYuzrv}`

