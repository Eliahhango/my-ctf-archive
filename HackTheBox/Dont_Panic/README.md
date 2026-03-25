# Dont Panic

## Overview

This directory contains the local materials and saved solve workflow for the `Don't Panic!` challenge on Hack The Box. This is a reversing challenge packaged as a small Rust binary. The underlying logic is simple: the program validates the user input byte by byte using a large set of tiny checker routines.

The main challenge is not defeating anti-analysis or solving obfuscation. It is recognizing that the binary has decomposed the flag check into many small per-character comparisons and then reconstructing the accepted input from those constants.

## Challenge Profile

- Challenge: `Don't Panic!`
- Category: `Reversing`
- Platform: `Hack The Box`
- Saved PoC: `dont_panic_poc.sh`

## Directory Contents

- `dont_panic_poc.sh`
- `rev_dontpanic/`
- `rev_dontpanic.zip`

## First Commands To Run

Start by inspecting the archive and the binary:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Dont_Panic"
ls -lah
unzip -l "rev_dontpanic.zip"
file rev_dontpanic/dontpanic
```

Read the saved PoC:

```bash
sed -n "1,220p" "dont_panic_poc.sh"
```

Run it:

```bash
chmod +x "dont_panic_poc.sh"
./dont_panic_poc.sh
```

## What The Binary Is Doing

The Rust program:

1. reads the candidate input
2. trims the trailing newline
3. enforces a fixed total length
4. dispatches each byte to its own small checker function

Each checker compares a single byte against a fixed constant. If the comparison fails, the program panics. If all checks pass, the input is accepted.

That structure makes the binary look more complicated than it really is, because there are many checker functions instead of one direct string comparison.

## Why The Solve Is Straightforward Once Identified

As soon as you realize each checker corresponds to one character position, the reversing task becomes:

- find the per-position comparison constants
- place them back in order
- reconstruct the accepted string

In other words, the challenge is using many tiny comparisons to disguise what is effectively a hardcoded flag check.

## Manual Analysis Commands

If you want to inspect the program yourself, these are good commands to start with:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Dont_Panic"
strings -n 5 rev_dontpanic/dontpanic | head -200
objdump -d -Mintel rev_dontpanic/dontpanic | less
```

If you prefer a reverse-engineering tool:

```bash
gdb -q rev_dontpanic/dontpanic
radare2 -AA rev_dontpanic/dontpanic
```

What to look for:

- the total required input length
- the central dispatcher or `check_flag` routine
- the individual byte-checker functions
- the immediate constants used in those comparisons

## What The Saved PoC Does

The saved script simply prints the reconstructed flag, because the hard part was the analysis of the binary rather than any live interaction. Once the byte constants were recovered, there was no reason to keep the solve more complicated than necessary.

## Reproduction Commands

Use this sequence for the fast path:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Dont_Panic"
unzip -l "rev_dontpanic.zip"
sed -n "1,220p" "dont_panic_poc.sh"
bash "dont_panic_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are practicing static reversing of validation logic. It is a good example of how a program can inflate the apparent complexity of a flag check while still boiling down to a list of fixed byte comparisons.
