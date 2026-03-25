# Dynastic

## Overview

This directory contains the local materials and saved solve workflow for the `Dynastic` challenge on Hack The Box. This is a classical-crypto challenge based on a position-dependent Caesar-style shift, better known as the Trithemius cipher.

The supplied source code already reveals the encryption logic. The task is therefore to reverse the transformation correctly and apply it to the provided output text.

## Challenge Profile

- Challenge: `Dynastic`
- Category: `Crypto`
- Platform: `Hack The Box`
- Saved PoC: `dynastic_poc.sh`

## Directory Contents

- `challenge_download`
- `crypto_dynastic/`
- `crypto_dynastic.zip`
- `dynastic_poc.sh`

## First Commands To Run

Start by reviewing the archive and the extracted files:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Dynastic"
ls -lah
unzip -l "crypto_dynastic.zip"
```

Inspect the challenge files:

```bash
sed -n '1,220p' crypto_dynastic/source.py
sed -n '1,120p' crypto_dynastic/output.txt
```

Read the saved PoC:

```bash
sed -n "1,220p" "dynastic_poc.sh"
```

Run it:

```bash
chmod +x "dynastic_poc.sh"
./dynastic_poc.sh
```

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

## What The Saved PoC Does

The PoC reads the final line of `output.txt`, reverses the per-position shift, and wraps the recovered plaintext inside the `HTB{...}` format expected by the challenge.

That makes the solve reproducible directly from the local files with no network dependency.

## Reproduction Commands

Use this sequence for the fast path:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Dynastic"
unzip -l "crypto_dynastic.zip"
sed -n '1,220p' crypto_dynastic/source.py
sed -n "1,220p" "dynastic_poc.sh"
bash "dynastic_poc.sh"
```

## Study Notes

This challenge is a good introduction to classical ciphers that vary by position rather than by a single fixed key. It is worth revisiting if you want practice translating a short encryption routine directly into its inverse.
