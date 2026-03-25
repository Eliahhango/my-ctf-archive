# Undo

## Overview

This directory contains the local materials and saved solve workflow for the `Undo` challenge from `picoCTF 2026`. The goal of this README is to make the folder immediately useful to someone reviewing the archive later: what the challenge was about, what files matter, how the solve works at a high level, and which commands to run first.

## Challenge Profile

- Challenge: `Undo`
- Category: `General Skills`
- Collection: `picoCTF`
- Event or Platform: `picoCTF 2026`
- Difficulty: `Medium`
- Author: `YAHAYA MEDDY`
- Saved PoC: `undo_poc.sh`

## Directory Contents

- `undo_poc.sh`

## First Commands To Run

Start by listing the directory and reading the saved proof-of-concept script. In this archive, the PoC comments are treated as the primary solve notes and usually contain the most important reasoning.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Undo"
ls -lah
sed -n "1,220p" "undo_poc.sh"
```

If you want to execute the saved solve directly:

```bash
chmod +x "undo_poc.sh"
./undo_poc.sh
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

## Reproduction Commands

Use this sequence if you want the shortest path from opening the folder to reproducing the saved solve:

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Undo"
sed -n "1,220p" "undo_poc.sh"
bash "undo_poc.sh"
```

## Study Notes

This folder is best used as a practical study reference for `General Skills`-style problems. The fastest path is to run the PoC, but the more valuable path is to read the solve notes first, inspect the local files yourself, and then compare your reasoning to the saved exploit or script.
