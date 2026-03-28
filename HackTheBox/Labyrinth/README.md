# Labyrinth

## Overview

This directory contains the local materials and manual walkthrough for the `Labyrinth` challenge on Hack The Box - CTF Try Out. This README is written as a practical walkthrough so someone can open the folder, inspect the challenge files, understand the intended weakness, and reproduce the solve with commands that are easy to copy and run.

## Challenge Profile

- Challenge: `Labyrinth`
- Category: `Pwn / Binary Exploitation`
- Platform: `Hack The Box - CTF Try Out`

## Directory Contents

- `challenge/`
- `labyrinth_poc.sh`
- `pwn_labyrinth.zip`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Labyrinth"
ls -lah
unzip -l "pwn_labyrinth.zip"
```

Useful first inspection commands:

```bash
file 'pwn_labyrinth.zip'
strings -n 5 'pwn_labyrinth.zip' | head -200
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Walkthrough

Challenge: Labyrinth
Platform: Hack The Box - CTF Try Out
Category: Pwn / Binary Exploitation

### Scenario summary

The binary presents 100 doors and makes the challenge sound like a "guess the
correct door" game. The catch is that door 69 unlocks a hidden second stage,
and that stage contains a classic stack overflow.

### Provided files

- pwn_labyrinth.zip
- challenge/labyrinth
- challenge/glibc/ld-linux-x86-64.so.2
- challenge/glibc/libc.so.6
- challenge/flag.txt

Remote target used during solve:
- 154.57.164.72:30444

Reversing notes:
After the banner, the program reads the chosen door with read_num().
If the first input is "69" or "069", it prints a hidden prompt and then does:

fgets(buffer, 0x44, stdin);

but the destination buffer is only 0x30 bytes long.

Stack layout in main():
rbp-0x30 ... rbp-0x01   buffer[48]
rbp+0x00                saved rbp
rbp+0x08                saved return address

So the exact overwrite distance is:
48 bytes -> reach saved rbp
56 bytes -> reach saved RIP

At first glance, the obvious move is to jump to escape_plan(), the hidden win
function. But returning to the *start* of that function is messy because it
builds a fresh stack frame and the overwritten context is not ideal.

The stable trick is better:
1. Overwrite saved rbp with a writable .bss address: 0x404150
2. Overwrite RIP with 0x401287

Why 0x401287?
It lands *inside* escape_plan() after the opening art has already been
handled, right before the code prints the congratulations line, opens
"./flag.txt", and reads the flag byte-by-byte.

Why overwrite saved rbp too?
Because this mid-function entry uses stack locals like [rbp-4] and [rbp-5].
If rbp is still junk from the overflow, those writes crash or corrupt
unmapped memory. Pointing rbp at writable .bss gives the function safe local
storage and lets the file-read loop complete cleanly.

Final payload layout:
"69\\n"                              -> unlock hidden branch
"A" * 48                            -> fill vulnerable buffer
p64(0x404150)                       -> saved rbp to writable memory
p64(0x401287)                       -> jump into file-reading part of win

### Real-world lesson

Not every stack overflow needs full shellcode or a long ROP chain. Many
practical exploits are simply "redirect execution into an already useful code
path" while fixing just enough surrounding state for that path to succeed.

Final live flag obtained during testing:
HTB{3sc4p3_fr0m_4b0v3}

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Labyrinth"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `HTB{3sc4p3_fr0m_4b0v3}`

## Study Notes

This challenge is worth revisiting if you are practicing `Pwn / Binary Exploitation` problems. Inspect the binary yourself first, confirm the weakness manually, and use the archived solve notes only after you have traced the bug and exploit path on your own.
