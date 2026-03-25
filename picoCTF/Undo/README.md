# Undo

## Overview

This directory contains the local materials and manual walkthrough for the `Undo` challenge from `picoCTF 2026`. The goal of this README is to make the folder immediately useful to someone reviewing the archive later: what the challenge was about, what files matter, how the solve works at a high level, and which commands to run first.

## Challenge Profile

- Challenge: `Undo`
- Category: `General Skills`
- Collection: `picoCTF`
- Event or Platform: `picoCTF 2026`
- Difficulty: `Medium`
- Author: `YAHAYA MEDDY`

## Directory Contents

- `undo_poc.sh`

## First Commands To Run

This folder does not include original challenge files. Start by reading the challenge description and the manual walkthrough below, then connect to a fresh challenge instance and reproduce the steps one by one.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Undo"
ls -lah
printf 'Follow the manual walkthrough below against the live service.\n'
```

## Walkthrough

Challenge Name: Undo
Category: General Skills
Difficulty: Medium
Event: picoCTF 2026
Author: YAHAYA MEDDY

### Description

Can you reverse a series of Linux text transformations to recover the original flag?

Given information:
Service: nc foggy-cliff.picoctf.net 54881
Starting transformed text:
KTJxNW85NjQ1LWZhMDFnQHplMHNmYTRlRy1nazNnLXRhMWZlcmlyRShTR1BicHZj

Solving idea:
Reverse each transformation in the opposite order from how it was applied.

### Step 1

Hint: Base64 encoded the string.
Manual command:
printf '%s' 'KTJxNW85NjQ1LWZhMDFnQHplMHNmYTRlRy1nazNnLXRhMWZlcmlyRShTR1BicHZj' | base64 -d
Reason:
The hint says the text was Base64 encoded, so decode it with `base64 -d`.
Output after this step:
)2q5o9645-fa01g@ze0sfa4eG-gk3g-ta1ferirE(SGPbpvc

### Step 2

Hint: Reversed the text.
Manual command:
printf '%s' ')2q5o9645-fa01g@ze0sfa4eG-gk3g-ta1ferirE(SGPbpvc' | rev
Reason:
The next hint says the text was reversed, so restore it with `rev`.
Output after this step:
cvpbPGS(Eriref1at-g3kg-Ge4afs0ez@g10af-5469o5q2)

### Step 3

Hint: Replaced underscores with dashes.
Manual command:
printf '%s' 'cvpbPGS(Eriref1at-g3kg-Ge4afs0ez@g10af-5469o5q2)' | tr '-' '_'
Reason:
Underscores were changed to dashes, so convert `-` back to `_` with `tr`.
Output after this step:
cvpbPGS(Eriref1at_g3kg_Ge4afs0ez@g10af_5469o5q2)

### Step 4

Hint: Replaced curly braces with parentheses.
Manual command:
printf '%s' 'cvpbPGS(Eriref1at_g3kg_Ge4afs0ez@g10af_5469o5q2)' | tr '()' '{}'
Reason:
Curly braces were replaced with parentheses, so convert `(` and `)` back to `{` and `}`.
Output after this step:
cvpbPGS{Eriref1at_g3kg_Ge4afs0ez@g10af_5469o5q2}

### Step 5

Hint: Applied ROT13 to letters.
Manual command:
printf '%s' 'cvpbPGS{Eriref1at_g3kg_Ge4afs0ez@g10af_5469o5q2}' | tr 'A-Za-z' 'N-ZA-Mn-za-m'
Reason:
ROT13 was applied to letters. ROT13 is symmetric, so applying it again restores the original text.
Output after this step:
picoCTF{Revers1ng_t3xt_Tr4nsf0rm@t10ns_5469b5d2}

### Flag obtained

picoCTF{Revers1ng_t3xt_Tr4nsf0rm@t10ns_5469b5d2}

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Undo"
ls -lah
```

## Study Notes

This folder is best used as a practical study reference for `General Skills`-style problems. Work through the manual inspection and exploitation steps first, then compare your reasoning against the archived solve notes if you want an extra cross-check.
