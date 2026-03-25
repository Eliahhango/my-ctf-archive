# Secure Password Database

## Overview

This directory contains the local materials and saved solve workflow for the `Secure Password Database` challenge from `picoCTF 2026`. The goal of this README is to make the folder immediately useful to someone reviewing the archive later: what the challenge was about, what files matter, how the solve works at a high level, and which commands to run first.

## Challenge Profile

- Challenge: `Secure Password Database`
- Category: `Reverse Engineering`
- Collection: `picoCTF`
- Event or Platform: `picoCTF 2026`
- Difficulty: `Medium`
- Author: `PHILIP THAYER`
- Saved PoC: `secure_password_database_poc.sh`

## Directory Contents

- `secure_password_database_poc.sh`
- `system.out`

## First Commands To Run

Start by listing the directory and reading the saved proof-of-concept script. In this archive, the PoC comments are treated as the primary solve notes and usually contain the most important reasoning.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Secure_Password_Database"
ls -lah
sed -n "1,220p" "secure_password_database_poc.sh"
```

If you want to execute the saved solve directly:

```bash
chmod +x "secure_password_database_poc.sh"
./secure_password_database_poc.sh
```

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

## Reproduction Commands

Use this sequence if you want the shortest path from opening the folder to reproducing the saved solve:

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Secure_Password_Database"
sed -n "1,220p" "secure_password_database_poc.sh"
bash "secure_password_database_poc.sh"
```

## Study Notes

This folder is best used as a practical study reference for `Reverse Engineering`-style problems. The fastest path is to run the PoC, but the more valuable path is to read the solve notes first, inspect the local files yourself, and then compare your reasoning to the saved exploit or script.
