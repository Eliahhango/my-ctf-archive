# GettingStarted

## Overview

This directory contains the local materials and manual walkthrough for the `GettingStarted` challenge on Hack The Box - CTF Try Out. This README is written as a practical walkthrough so someone can open the folder, inspect the challenge files, understand the intended weakness, and reproduce the solve with commands that are easy to copy and run.

## Challenge Profile

- Challenge: `GettingStarted`
- Category: `Pwn / Binary Exploitation`
- Platform: `Hack The Box - CTF Try Out`

## Directory Contents

- `challenge/`
- `getting_started_poc.sh`
- `pwn_getting_started.zip`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/GettingStarted"
ls -lah
unzip -l "pwn_getting_started.zip"
```

Useful first inspection commands:

```bash
file 'pwn_getting_started.zip'
strings -n 5 'pwn_getting_started.zip' | head -200
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

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

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/GettingStarted"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `HTB{b0f_tut0r14l5_4r3_g00d}`

## Study Notes

This challenge is worth revisiting if you are practicing `Pwn / Binary Exploitation` problems. Inspect the binary yourself first, confirm the weakness manually, and use the archived solve notes only after you have traced the bug and exploit path on your own.
