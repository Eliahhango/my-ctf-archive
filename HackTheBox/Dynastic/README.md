# Dynastic

## Overview

This directory contains the local materials and manual walkthrough for the `Dynastic` challenge on Hack The Box. This is a classical-crypto challenge based on a position-dependent Caesar-style shift, better known as the Trithemius cipher.

The supplied source code already reveals the encryption logic. The task is therefore to reverse the transformation correctly and apply it to the provided output text.

## Challenge Profile

- Challenge: `Dynastic`
- Category: `Crypto`
- Platform: `Hack The Box`

## Directory Contents

- `challenge_download`
- `crypto_dynastic/`
- `crypto_dynastic.zip`
- `dynastic_poc.sh`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Dynastic"
ls -lah
unzip -l "crypto_dynastic.zip"
```

Useful first inspection commands:

```bash
find challenge_download -maxdepth 2 -type f | sort
file 'crypto_dynastic.zip'
strings -n 5 'crypto_dynastic.zip' | head -200
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Cipher Logic

The challenge uses a position-based shift. For each alphabetic character, the plaintext letter is shifted forward by its index in the string. Non-alphabetic characters are left unchanged.

So if the encryption logic is:

```text
ciphertext[i] = plaintext[i] + i (mod 26)
```

then decryption is simply:

```text
plaintext[i] = ciphertext[i] - i (mod 26)
```

That is why this challenge is straightforward once you inspect the provided Python source.

## Why This Is Not Just A Normal Caesar Cipher

A normal Caesar cipher uses one fixed shift for the entire message. Here, the shift changes for every character position:

- position 0 uses shift 0
- position 1 uses shift 1
- position 2 uses shift 2
- and so on

That makes it a progressive shift cipher rather than a single-offset substitution.

## Manual Solve Idea

If you want to work it through manually, open the provided source code and output file first:

```bash
sed -n '1,220p' crypto_dynastic/source.py
cat crypto_dynastic/output.txt
```

Then apply the reverse shift for each alphabetic character. A short Python snippet is the most practical way to do this:

```bash
python3 - <<'PY'
from pathlib import Path

ciphertext = Path("crypto_dynastic/output.txt").read_text().splitlines()[-1].strip()
plaintext = []

for i, ch in enumerate(ciphertext):
    if ch.isalpha():
        val = (ord(ch) - ord("A") - i) % 26
        plaintext.append(chr(val + ord("A")))
    else:
        plaintext.append(ch)

print("".join(plaintext))
PY
```

## Optional Archive Reference

The archived notes in this folder reverse the per-position shift from the final line of `output.txt` and reconstruct the plaintext flag.

That makes the solve reproducible directly from the local files with no network dependency.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Dynastic"
ls -lah
```

## Final Flags

Following the manual path in this README leads to these recovered flags:

- `HTB{DID_YOU_KNOW_ABOUT_THE_TRITHEMIUS_CIPHER?!_IT_IS_SIMILAR_TO_CAESAR_CIPHER}`
- `HTB{{{message}`

## Study Notes

This challenge is a good introduction to classical ciphers that vary by position rather than by a single fixed key. It is worth revisiting if you want practice translating a short encryption routine directly into its inverse.
