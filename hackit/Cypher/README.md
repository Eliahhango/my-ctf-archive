# Cypher

## Overview

This directory contains the local notes and manual walkthrough for the `Cypher`
challenge from `HackIT`. This is a short classical-crypto problem where the
provided ciphertext is decoded with the Atbash substitution cipher.

## Challenge Profile

- Challenge: `Cypher`
- Category: `Crypto`
- Platform: `HackIT`
- Points: `50`

## Directory Contents

- `challenge.txt`
- `cypher_poc.sh`

## First Commands To Run

Start with the archived challenge text in this folder. Treat this like a proper
writeup: inspect what was provided, identify the cipher family, verify the
transformation with a command, and continue until you can see the final flag.

```bash
cd "/home/eliah/Desktop/CTF/hackit/Cypher"
ls -lah
sed -n '1,120p' challenge.txt
```

Useful first inspection command:

```bash
bash ./cypher_poc.sh
```

## Writeup Flow

This README follows the same solve structure as the rest of the workspace:
start from the provided challenge text, identify the exact crypto primitive,
verify it with a reproducible command, and stop only when the final flag is
visible.

When you work through it, keep asking four questions:

1. What exact ciphertext did the challenge give me?
2. What clue in the wording points to the right cipher?
3. How do I verify the suspected cipher with a command?
4. Does the decoded output form a valid-looking flag?

## Walkthrough

Challenge Name: Cypher
Category: Crypto
Platform: HackIT
Points: 50

### Description

"How about bashing this cipher:
TIS{ZgYzhs_Xrksvi_Prwwl!}"

### Step 1: Inspect the ciphertext carefully.

Manual command:

```bash
sed -n '1,120p' challenge.txt
```

Important observations:

- The string is already in a flag-like format: `TIS{...}`
- The inner words preserve case and separators with underscores.
- The prompt says "bashing this cipher", which is a strong hint toward
  `Atbash`
- The platform accepts solved flags with a `GoH{...}` wrapper, so the outer
  `TIS{...}` text should be treated as part of the puzzle presentation rather
  than the final submission prefix.

Why this matters:

Atbash is a mirrored alphabet substitution:

- `A <-> Z`
- `B <-> Y`
- `C <-> X`

The challenge title and wording are likely nudging us directly toward that
transformation rather than a keyed cipher or frequency-analysis problem.

### Step 2: Test the Atbash hypothesis on one word.

Manual mental check:

- `ZgYzhs` becomes `AtBash`

Why this matters:

A partial decode that immediately turns into a meaningful word is usually
enough to confirm the cipher family for a short beginner crypto challenge.

### Step 3: Decode only the payload inside the braces and rebuild the accepted flag.

Manual command:

```bash
bash ./cypher_poc.sh
```

What the script does:

- reads the provided ciphertext
- decodes only the inner payload with Atbash
- rebuilds the final answer with the accepted `GoH{...}` wrapper
- mirrors uppercase letters across `A-Z`
- mirrors lowercase letters across `a-z`
- leaves `_` and `!` unchanged

Recovered plaintext:

`GoH{AtBash_Cipher_Kiddo!}`

### Why this works

Atbash does not use a key. It is a fixed substitution cipher where each letter
is replaced by its opposite in the alphabet. That means encryption and
decryption are the same operation.

In this challenge, the practical detail is that the displayed wrapper is not
the accepted submission prefix. The intended decode target is the text inside
the braces, and the final answer must be submitted in the platform's
`GoH{...}` format.

Examples:

- `Z` -> `A`
- `g` -> `t`
- `X` -> `C`
- `r` -> `i`

Real-world lesson:

Very weak classical ciphers can often be broken instantly when:

- the challenge name hints at the method
- the output preserves word structure
- the format already looks like a flag

The main skill here is fast recognition, not heavy computation.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path.

```bash
cd "/home/eliah/Desktop/CTF/hackit/Cypher"
ls -lah
bash ./cypher_poc.sh
```

## Final Flag

Following the manual path in this README leads to:
`GoH{AtBash_Cipher_Kiddo!}`

## Study Notes

This is a good warm-up challenge for spotting classical substitution ciphers
from challenge wording and output structure. It is worth remembering that
Atbash is symmetric: the same transformation both encrypts and decrypts.
