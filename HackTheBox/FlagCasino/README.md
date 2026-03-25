# FlagCasino

## Overview

This directory contains the local materials and saved solve workflow for the `FlagCasino` challenge on Hack The Box. This is a reversing challenge built around poor use of `rand()`. The binary tries to look like a game of chance, but its randomness is fully predictable because each round reseeds the PRNG from a single input byte.

The solve is a clean demonstration of why repeated reseeding with tiny inputs makes “random” validation logic easy to reverse.

## Challenge Profile

- Challenge: `FlagCasino`
- Category: `Reversing`
- Platform: `Hack The Box`
- Saved PoC: `flagcasino_poc.sh`

## Directory Contents

- `flagcasino_poc.sh`
- `rev_flagcasino/`
- `rev_flagcasino.zip`

## First Commands To Run

Start by reviewing the folder and archive:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/FlagCasino"
ls -lah
unzip -l "rev_flagcasino.zip"
file rev_flagcasino/casino
```

Read the saved PoC:

```bash
sed -n "1,220p" "flagcasino_poc.sh"
```

Run it:

```bash
chmod +x "flagcasino_poc.sh"
./flagcasino_poc.sh
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

## What The Saved PoC Does

The PoC reads the binary, extracts the table from the known offset, loads libc with `ctypes`, and then reproduces the same `srand` / `rand` behavior locally. For each target integer in the table, it tests all 256 candidate bytes until the first `rand()` output matches.

That directly reconstructs the flag.

## Reproduction Commands

Use this sequence for the fast path:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/FlagCasino"
unzip -l "rev_flagcasino.zip"
sed -n "1,220p" "flagcasino_poc.sh"
bash "flagcasino_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are practicing reversing of weak PRNG logic. It is a strong reminder that a program can look “random” while actually being completely deterministic and easy to invert once the seeding strategy is understood.
