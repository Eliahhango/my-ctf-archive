# Abyss

## Overview

This directory contains the local materials and saved solve workflow for the `Abyss` challenge on Hack The Box CTF Try Out. This is a binary exploitation challenge built around an unsafe login parser. The important idea is not just that a buffer can be overflowed, but that the overflow happens because raw input from `read()` is later treated like a NUL-terminated C string.

The saved PoC in this folder is intended to be the practical reproduction path. This README expands the reasoning so that someone who has never seen the challenge before can inspect the binary, understand the bug, and then run the exploit with confidence.

## Challenge Profile

- Challenge: `Abyss`
- Category: `Pwn / Binary Exploitation`
- Platform: `Hack The Box - CTF Try Out`
- Saved PoC: `abyss_poc.sh`

## Directory Contents

- `abyss_poc.sh`
- `pwn_abyss/`
- `pwn_abyss.zip`

## First Commands To Run

Start by reviewing the files in the directory and confirming what was shipped with the challenge.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Abyss"
ls -lah
unzip -l "pwn_abyss.zip"
```

If you want to inspect the extracted binary manually before running the PoC, these commands are a good starting point:

```bash
file pwn_abyss/*
checksec --file=pwn_abyss/abyss
strings -n 5 pwn_abyss/abyss | head -200
```

Read the PoC comments next. They summarize the exact exploit path.

```bash
sed -n "1,220p" "abyss_poc.sh"
```

Run the exploit:

```bash
chmod +x "abyss_poc.sh"
./abyss_poc.sh
```

To reuse the same exploit against a fresh spawned instance:

```bash
./abyss_poc.sh <HOST> <PORT>
```

## What The Binary Does

The program implements a small command protocol with three actions:

- `0` for login
- `1` for read
- `2` for exit

At a high level, it looks like a normal authenticated file reader. The login routine accepts a `USER ...` line and a `PASS ...` line, compares them against credentials loaded from `.creds`, and only then allows the read path to continue.

That design is misleading. The real weakness is in how the parser handles the raw data returned by `read()`.

## Root Cause

The vulnerable function reads a full block of bytes into a stack buffer and then copies bytes into local arrays until a NUL byte is encountered. The problem is that `read()` does not append a terminator. If the attacker sends a full-size input with no `\x00` byte, the parser keeps walking past the end of the intended input and begins reading adjacent stack memory as if it were still part of the string.

That turns a parsing bug into a controllable stack overflow.

This is the exact lesson the challenge is built to teach: unstructured input from `read()`, `recv()`, or `fread()` is not automatically safe to treat as a string. If a developer forgets to terminate it or fails to track the exact byte count, later string logic can walk out of bounds and corrupt memory.

## Exploitation Strategy

The exploit does not need a long ROP chain. A simpler and cleaner path works.

1. Connect to the target.
2. Send the command integer for login.
3. Send a crafted `USER` value.
4. Send a full-sized `PASS` value that contains no NUL byte.
5. Let the vulnerable parser overflow into the saved return address.
6. Perform a partial return-address overwrite so execution lands inside `cmd_read()`.
7. Skip the authentication check and provide `flag.txt` as the filename.

The saved exploit uses a partial overwrite instead of a full 8-byte address because the vulnerable loop stops on the first NUL byte. A full 64-bit pointer would introduce zero bytes too early. Overwriting only the low bytes avoids that issue and is enough to redirect control flow.

## Why The Partial Overwrite Works

The intended return target is `0x4014eb`, which is already inside the file-read logic after the logged-in check has succeeded. That is more reliable than trying to build a larger chain.

The PoC therefore uses:

- a carefully aligned `USER` payload
- a full-sized `PASS` payload with no terminator
- the low three bytes of the target address

That combination is enough to turn the parser bug into an authentication bypass and direct file read.

## Manual Analysis Commands

If you want to retrace the solve manually, these are good commands to run:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Abyss"
objdump -d -Mintel pwn_abyss/abyss | less
strings -n 5 pwn_abyss/abyss | less
gdb -q pwn_abyss/abyss
```

Inside `gdb`, the usual path is:

```gdb
disassemble main
disassemble cmd_login
disassemble cmd_read
```

What you are looking for:

- where the input buffer is allocated
- where the parser copies `USER` and `PASS`
- where the copy loop stops
- where the return address sits relative to the stack buffer
- where a useful re-entry point exists in the read path

## Reproduction Commands

If you want the shortest path from opening the folder to reproducing the solve, use this sequence:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Abyss"
unzip -l "pwn_abyss.zip"
sed -n "1,220p" "abyss_poc.sh"
bash "abyss_poc.sh"
```

## Study Notes

This is a useful challenge for practicing three core exploitation ideas:

- the difference between raw byte input and C strings
- parser-driven overflows that do not look like classic `gets()` bugs
- partial return-address overwrites when full pointers are inconvenient

The PoC gives the fast result, but the deeper learning comes from stepping through the vulnerable login parser and watching how the unterminated `PASS` input changes stack state.
