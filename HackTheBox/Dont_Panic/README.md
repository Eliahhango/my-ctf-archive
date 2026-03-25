# Dont Panic

## Overview

This directory contains the local materials and manual walkthrough for the `Don't Panic!` challenge on Hack The Box. This is a reversing challenge packaged as a small Rust binary. The underlying logic is simple: the program validates the user input byte by byte using a large set of tiny checker routines.

The main challenge is not defeating anti-analysis or solving obfuscation. It is recognizing that the binary has decomposed the flag check into many small per-character comparisons and then reconstructing the accepted input from those constants.

## Challenge Profile

- Challenge: `Don't Panic!`
- Category: `Reversing`
- Platform: `Hack The Box`

## Directory Contents

- `dont_panic_poc.sh`
- `rev_dontpanic/`
- `rev_dontpanic.zip`

## First Commands To Run

Start with the original challenge materials in this folder. The goal is to identify the bug or recovery path from the provided files, then follow the numbered walkthrough below to reach the flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Dont_Panic"
ls -lah
unzip -l "rev_dontpanic.zip"
```

Useful first inspection commands:

```bash
file 'rev_dontpanic.zip'
strings -n 5 'rev_dontpanic.zip' | head -200
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

## Optional Archive Reference

Once the byte constants are recovered, the solve is fully manual: reconstruct the accepted string and submit it. The hard part is the analysis, not the final interaction.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Dont_Panic"
ls -lah
```

## Study Notes

This challenge is worth revisiting if you are practicing static reversing of validation logic. It is a good example of how a program can inflate the apparent complexity of a flag check while still boiling down to a list of fixed byte comparisons.
