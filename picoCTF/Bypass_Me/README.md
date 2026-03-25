# Bypass Me

## Overview

This directory contains the local materials and manual walkthrough for the `Bypass Me` challenge from `picoCTF 2026`. This is a reversing challenge built around a common pattern: the program appears to sanitize input and hides its password behind light obfuscation, but the real security decision is based on the raw decoded value rather than the cleaned-up display output.

The solve is mostly about following the actual comparison path, recovering the XOR-obfuscated password, and then using it in the real runtime environment.

## Challenge Profile

- Challenge: `Bypass Me`
- Category: `Reverse Engineering`
- Collection: `picoCTF`
- Event or Platform: `picoCTF 2026`
- Difficulty: `Medium`
- Author: `PRINCE NIYONSHUTI N.`

## Directory Contents

- `bypass_me_poc.sh`
- `bypassme.bin`

## First Commands To Run

Start with the original challenge materials in this folder. The goal is to identify the bug or recovery path from the provided files, then follow the numbered walkthrough below to reach the flag manually.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Bypass_Me"
ls -lah
```

Useful first inspection commands:

```bash
file 'bypassme.bin'
strings -n 5 'bypassme.bin' | head -200
```

## Core Reversing Lesson

The challenge encourages you to think about sanitization, but the important idea is that the sanitized output is only cosmetic. The actual authentication check uses the raw input buffer and compares it against a password reconstructed at runtime.

That means there are two separate data paths:

- a display path that shows sanitized input
- a security path that compares the raw input

Only the second one matters for solving the challenge.

This is a very useful real-world habit in reverse engineering and application review: always trace the variable that reaches the trust decision, not the variable that is logged or displayed.

## What The Binary Is Doing

The binary:

- decodes an obfuscated password at runtime
- prints raw and sanitized input
- compares the raw input to the decoded password

The obfuscation is simple XOR with a fixed byte (`0xaa`). Once the obfuscated bytes are found in the binary, recovering the real password is trivial.

The recovered bytes decode to:

```text
SuperSecure
```

## Why XOR Obfuscation Is Weak

XOR with a fixed key is not real secret storage. If:

```text
hidden = original ^ key
```

then the original is recovered with:

```text
original = hidden ^ key
```

That is why this pattern is common in beginner reversing challenges: it hides the plaintext from a naive strings scan, but it does not resist static analysis.

## Manual Analysis Workflow

Good commands for manual inspection:

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Bypass_Me"
strings -n 4 bypassme.bin
objdump -d -Mintel bypassme.bin | less
objdump -d -Mintel bypassme.bin | sed -n '/<_Z15decode_passwordPc>:/,/^$/p'
objdump -d -Mintel bypassme.bin | sed -n '/<_Z8sanitizePKcPc>:/,/^$/p'
```

What to verify:

- where the obfuscated bytes live
- how `decode_password()` transforms them
- what `sanitize()` really does
- which buffer is passed into `strcmp()`

Once you confirm that `strcmp()` uses the raw buffer, the “sanitized input” output becomes a distraction rather than a protection.

## Why The Remote Step Matters

Locally, you can validate the recovered password against the binary, but the real flag file exists only on the challenge server. That is why the archived reference notes uses SSH to run the binary remotely with the recovered password.

The local analysis proves the password. The remote run retrieves the flag.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Bypass_Me"
ls -lah
```

## Study Notes

This challenge is worth revisiting if you are practicing static reversing of lightly obfuscated secrets. It is also a good reminder that visible sanitization or “security-looking” output does not necessarily correspond to the real validation path.
