# GettingStarted

## Overview

This directory contains the local materials and saved solve workflow for the `GettingStarted` challenge on Hack The Box - CTF Try Out. This README is written as a practical walkthrough so someone can open the folder, inspect the challenge files, understand the intended weakness, and reproduce the solve with commands that are easy to copy and run.

## Challenge Profile

- Challenge: `GettingStarted`
- Category: `Pwn / Binary Exploitation`
- Platform: `Hack The Box - CTF Try Out`
- Saved PoC: `getting_started_poc.sh`

## Directory Contents

- `challenge/`
- `getting_started_poc.sh`
- `pwn_getting_started.zip`

## First Commands To Run

Begin with a short inventory so you can see the original challenge archive, any extracted directories, and the solve script saved in this folder.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/GettingStarted"
ls -lah
```

If you want to verify what was originally provided by Hack The Box, inspect the archive contents before extracting or re-extracting them.

```bash
unzip -l "pwn_getting_started.zip"
```

Read the top of the PoC first. The comments there summarize the exact idea used during the solve and usually explain the bug, leak, algorithm, or reversing trick directly.

```bash
sed -n "1,220p" "getting_started_poc.sh"
```

Run the PoC after reviewing the notes.

```bash
chmod +x "getting_started_poc.sh"
./getting_started_poc.sh
```

If the script targets a spawned remote service, you can usually point it at a fresh instance by supplying a host and port.

```bash
./getting_started_poc.sh <HOST> <PORT>
```

## Walkthrough

Challenge: GettingStarted
Platform: Hack The Box - CTF Try Out
Category: Pwn / Binary Exploitation

### Scenario summary

This is a beginner stack-overflow challenge. The binary prints the stack
layout for us, then asks for input. Our job is not to fully hijack control
flow yet. We only need to overflow a stack buffer far enough to corrupt a
nearby variable named "target".

### Real-world concept

In unsafe native code, data placed next to a buffer on the stack can be
changed if input is copied without proper bounds checking. Even when we do
not control RIP yet, changing a security-relevant variable can still be
enough to win. This is the same mindset used in many real exploits:
attackers first look for the *smallest useful corruption* before going for
full code execution.

### Provided files

- pwn_getting_started.zip
- challenge/gs
- challenge/wrapper.py
- challenge/glibc/libc.so.6
- challenge/glibc/ld-linux-x86-64.so.2

Remote target used during solve:
- 154.57.164.67:31260

Important observation from reversing:
main() allocates 0x30 bytes on the stack and lays out local data as:
buffer[32]  at rbp-0x30
alignment   at rbp-0x10
target      at rbp-0x08

The code initializes target to 0xdeadbeef and later does:
if (target != 0xdeadbeef) { win(); }

That means the easiest exploit is:
1. Fill the 32-byte buffer
2. Overwrite the 8-byte alignment dummy
3. Continue into target so it is no longer 0xdeadbeef

Offset math:
32 bytes buffer
+ 8 bytes alignment
= 40 bytes to reach target

We send 44 'A' bytes.
Why 44?
- bytes 0..31 fill the buffer
- bytes 32..39 overwrite alignment
- bytes 40..43 overwrite the low 4 bytes of target with 0x41414141
- the trailing NUL written by scanf lands inside the target field, which is
still fine because the value is no longer 0xdeadbeef

Manual reproduction idea:
python3 -c 'print("A"*44)' | nc 154.57.164.67 31260

Final live flag obtained during testing:
HTB{b0f_tut0r14l5_4r3_g00d}

## Reproduction Commands

Use the following command sequence if you want a short and reliable path from opening the folder to reproducing the saved solve.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/GettingStarted"
unzip -l "pwn_getting_started.zip"
sed -n "1,220p" "getting_started_poc.sh"
bash "getting_started_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are practicing `Pwn / Binary Exploitation` problems. The saved PoC is meant to be the fast path, but the better learning path is to inspect the provided files yourself first, confirm the weakness manually, and then compare your reasoning with the script comments and implementation.
