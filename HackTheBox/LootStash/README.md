# LootStash

## Overview

This directory contains the local materials and saved solve workflow for the `LootStash` challenge on Hack The Box. This is a reversing challenge where the program appears to rely on `rand()` and time-based behavior, but the actual secret is stored directly inside a static loot table in the binary.

The clean solve is therefore static extraction rather than trying to race or predict the runtime selection.

## Challenge Profile

- Challenge: `LootStash`
- Category: `Reversing`
- Platform: `Hack The Box`
- Saved PoC: `lootstash_poc.sh`

## Directory Contents

- `lootstash_poc.sh`
- `rev_lootstash/`
- `rev_lootstash.zip`

## First Commands To Run

Start by inspecting the archive and extracted binary:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/LootStash"
ls -lah
unzip -l "rev_lootstash.zip"
file rev_lootstash/stash
```

Read the saved PoC:

```bash
sed -n "1,220p" "lootstash_poc.sh"
```

Run it:

```bash
chmod +x "lootstash_poc.sh"
./lootstash_poc.sh
```

## What The Binary Appears To Do

At runtime, the program seeds `rand()` with the current time, chooses one index from a large static loot table, and prints the corresponding item. That setup makes it look like the solve might require:

- repeated execution
- timing manipulation
- predicting the PRNG state

But that is not actually necessary.

## Why Static Analysis Wins

The important observation is that the flag is already embedded as one of the loot strings in the binary. If the flag exists as plaintext in the static table, there is no need to solve the runtime randomness at all. The simplest answer is to extract strings from the binary and search for the `HTB{...}` pattern.

That makes this challenge a good example of an important reversing principle: always check whether the secret is already present in static data before investing effort into dynamic logic.

## Manual Analysis Commands

These commands are enough to recover the flag manually:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/LootStash"
strings -n 5 rev_lootstash/stash | less
strings -n 5 rev_lootstash/stash | grep 'HTB{'
```

If you want to inspect the binary more generally:

```bash
objdump -d -Mintel rev_lootstash/stash | less
readelf -S rev_lootstash/stash
```

But for the actual solve, simple string extraction is sufficient.

## What The Saved PoC Does

The PoC runs `strings` against the binary, searches for a pattern matching `HTB{...}`, and prints the recovered flag. It intentionally avoids unnecessary complexity because the challenge does not require dynamic instrumentation once the static embedding is recognized.

## Reproduction Commands

Use this sequence for the fast path:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/LootStash"
unzip -l "rev_lootstash.zip"
strings -n 5 rev_lootstash/stash | grep 'HTB{'
sed -n "1,220p" "lootstash_poc.sh"
bash "lootstash_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are practicing basic static reversing. It is a strong reminder to check the obvious data sections first. Many binaries hide their secrets poorly, and a fast strings-based inspection can save a lot of unnecessary time.
