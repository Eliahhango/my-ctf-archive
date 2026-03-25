# FlagCasino

## Overview

This directory contains the local materials and manual walkthrough for the `FlagCasino` challenge on Hack The Box. This is a reversing challenge built around poor use of `rand()`. The binary tries to look like a game of chance, but its randomness is fully predictable because each round reseeds the PRNG from a single input byte.

The solve is a clean demonstration of why repeated reseeding with tiny inputs makes “random” validation logic easy to reverse.

## Challenge Profile

- Challenge: `FlagCasino`
- Category: `Reversing`
- Platform: `Hack The Box`

## Directory Contents

- `flagcasino_poc.sh`
- `rev_flagcasino/`
- `rev_flagcasino.zip`

## First Commands To Run

Start with the original challenge materials in this folder. The goal is to identify the bug or recovery path from the provided files, then follow the numbered walkthrough below to reach the flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/FlagCasino"
ls -lah
unzip -l "rev_flagcasino.zip"
```

Useful first inspection commands:

```bash
file 'rev_flagcasino.zip'
strings -n 5 'rev_flagcasino.zip' | head -200
```

## What The Binary Does

The binary checks the flag one byte at a time. For each position:

1. it reads one candidate byte
2. it calls `srand(candidate_byte)`
3. it calls `rand()`
4. it compares that first `rand()` output to a constant in a table

That is the key weakness. Because the seed is reset every round and because the seed space is only one byte wide, each character can be recovered independently by brute force.

## Why The Check Is Weak

This is not real randomness from the attacker’s point of view. The validation reduces to:

```text
Find the byte x such that rand() after srand(x) equals check[i]
```

There are only 256 possible values for `x`, so for each position we can try all possibilities and keep the one that matches the expected table entry.

That makes the whole flag reconstruction straightforward:

- extract the `check` table from the binary
- for each table entry, brute force the seed byte that reproduces it
- join the resulting bytes

## Manual Analysis Commands

If you want to inspect the binary yourself, these are good starting commands:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/FlagCasino"
strings -n 5 rev_flagcasino/casino | head -200
objdump -d -Mintel rev_flagcasino/casino | less
readelf -S rev_flagcasino/casino
```

What you want to identify:

- where the `check` table is stored
- how many positions are checked
- where `srand()` and `rand()` are used
- whether the seed depends on more than one byte

Once you confirm the seed is just the current character, the brute-force approach is obvious.

## Optional Archive Reference

The archived notes in this folder extract the table from the binary, reproduce the same `srand` / `rand` behavior locally, and brute-force each byte position until the outputs match.

That directly reconstructs the flag.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/FlagCasino"
ls -lah
```

## Study Notes

This challenge is worth revisiting if you are practicing reversing of weak PRNG logic. It is a strong reminder that a program can look “random” while actually being completely deterministic and easy to invert once the seeding strategy is understood.
