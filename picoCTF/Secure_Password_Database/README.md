# Secure Password Database

## Overview

This directory contains the local materials and manual walkthrough for the `Secure Password Database` challenge from `picoCTF 2026`. The goal of this README is to make the folder immediately useful to someone reviewing the archive later: what the challenge was about, what files matter, how the solve works at a high level, and which commands to run first.

## Challenge Profile

- Challenge: `Secure Password Database`
- Category: `Reverse Engineering`
- Collection: `picoCTF`
- Event or Platform: `picoCTF 2026`
- Difficulty: `Medium`
- Author: `PHILIP THAYER`

## Directory Contents

- `secure_password_database_poc.sh`
- `system.out`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Secure_Password_Database"
ls -lah
```

Useful first inspection commands:

```bash
file 'system.out'
strings -n 5 'system.out' | head -200
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Walkthrough

Challenge Name: Secure Password Database
Category: Reverse Engineering
Difficulty: Medium
Event: picoCTF 2026
Author: PHILIP THAYER

### Description

I made a new password authentication program that even shows you the password
you entered saved in the database! Isn't that cool?

Given information:
File: system.out
Service: nc candy-mountain.picoctf.net 59219

Solving idea:
1. Reverse the local ELF binary to recover how the program builds the secret.
2. Extract the hidden bytes from .rodata and undo the XOR with 0xaa.
3. Recreate the custom hash() routine.
4. Send the resulting decimal hash to the remote service to get the flag.

### Step 1: Inspect the main logic.

Manual command:
objdump -d -Mintel system.out | sed -n '/<main>:/,/^$/p'
Reason:
This shows that main copies bytes from obf_bytes, XORs each byte with 0xaa,
then calls make_secret() and compares your input to the result of hash().

### Step 2: Inspect the helper functions.

Manual command:
objdump -d -Mintel system.out | sed -n '/<hash>:/,/^$/p;/<make_secret>:/,/^$/p'
Reason:
This reveals the custom hash algorithm:
hash = (hash * 33) + current_byte
starting from 0x1505 until the null terminator.

### Step 3: Extract the obfuscated bytes.

Manual command:
objdump -s -j .rodata system.out | sed -n '1,40p'
Reason:
At address 0x2008 the binary stores these bytes:
c3 ff c8 c2 92 9b 8b c0 80 c2 c4 8b
XOR each one with 0xaa to recover the secret:
iUbh81!j*hn!

### Step 4: Compute the 64-bit wrapped hash.

Manual command:
python3 - <<'PY'
secret = b'iUbh81!j*hn!'
h = 0x1505
for b in secret:
h = ((h << 5) + h + b) & ((1 << 64) - 1)
print(h)
PY
Reason:
The binary uses an unsigned 64-bit return value, so we keep the result wrapped
to 64 bits. The correct hash is:
15237662580160011234

### Step 5: Submit the hash to the remote service.

Manual command:
printf 'A\n80\n15237662580160011234\n' | nc candy-mountain.picoctf.net 59219
Reason:
Any short password works for the leak stage. The final decimal value is what
the program actually checks before printing the flag.

### Flag obtained

picoCTF{d0nt_trust_us3rs}

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Secure_Password_Database"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `picoCTF{d0nt_trust_us3rs}`

## Study Notes

This folder is best used as a practical study reference for `Reverse Engineering`-style problems. Reverse the binary or artifact manually first, then compare your recovered constants or logic against the archived solve notes.
