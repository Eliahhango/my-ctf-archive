# Labyrinth

## Overview

This directory contains the local materials and saved solve workflow for the `Labyrinth` challenge on Hack The Box - CTF Try Out. This README is written as a practical walkthrough so someone can open the folder, inspect the challenge files, understand the intended weakness, and reproduce the solve with commands that are easy to copy and run.

## Challenge Profile

- Challenge: `Labyrinth`
- Category: `Pwn / Binary Exploitation`
- Platform: `Hack The Box - CTF Try Out`
- Saved PoC: `labyrinth_poc.sh`

## Directory Contents

- `challenge/`
- `labyrinth_poc.sh`
- `pwn_labyrinth.zip`

## First Commands To Run

Begin with a short inventory so you can see the original challenge archive, any extracted directories, and the solve script saved in this folder.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Labyrinth"
ls -lah
```

If you want to verify what was originally provided by Hack The Box, inspect the archive contents before extracting or re-extracting them.

```bash
unzip -l "pwn_labyrinth.zip"
```

Read the top of the PoC first. The comments there summarize the exact idea used during the solve and usually explain the bug, leak, algorithm, or reversing trick directly.

```bash
sed -n "1,220p" "labyrinth_poc.sh"
```

Run the PoC after reviewing the notes.

```bash
chmod +x "labyrinth_poc.sh"
./labyrinth_poc.sh
```

If the script targets a spawned remote service, you can usually point it at a fresh instance by supplying a host and port.

```bash
./labyrinth_poc.sh <HOST> <PORT>
```

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

## Reproduction Commands

Use the following command sequence if you want a short and reliable path from opening the folder to reproducing the saved solve.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Labyrinth"
unzip -l "pwn_labyrinth.zip"
sed -n "1,220p" "labyrinth_poc.sh"
bash "labyrinth_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are practicing `Pwn / Binary Exploitation` problems. The saved PoC is meant to be the fast path, but the better learning path is to inspect the provided files yourself first, confirm the weakness manually, and then compare your reasoning with the script comments and implementation.
