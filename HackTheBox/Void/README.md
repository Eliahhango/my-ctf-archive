# Void

## Overview

This directory contains the local materials and manual walkthrough for the `Void` challenge on Hack The Box CTF Try Out. This is a compact binary exploitation challenge whose main lesson is that even a tiny binary with almost no imported functions can still be exploited if the attacker understands how ELF dynamic resolution works.

The archived notes in this folder preserve one working payload, while this README explains why those bytes are needed and how the attack works conceptually.

## Challenge Profile

- Challenge: `Void`
- Category: `Pwn / Binary Exploitation`
- Platform: `Hack The Box - CTF Try Out`

## Directory Contents

- `challenge/`
- `pwn_void.zip`
- `void_poc.sh`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Void"
ls -lah
unzip -l "pwn_void.zip"
```

Useful first inspection commands:

```bash
file 'pwn_void.zip'
strings -n 5 'pwn_void.zip' | head -200
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Vulnerable Function

The core bug is very small:

```c
void vuln() {
    char buf[0x40];
    read(0, buf, 0xc8);
}
```

That means:

- the stack buffer is `0x40` bytes
- saved `rbp` adds another `8` bytes
- saved `rip` is reached at offset `72`

This is a textbook stack overflow. The challenge becomes interesting because the binary is intentionally stripped down.

## Why A Standard ret2win Approach Does Not Work

There is no convenient `win()` function. The import table is tiny. The binary does not hand us the usual building blocks for a straightforward libc leak and follow-up `system("/bin/sh")` chain.

That pushes the solve toward a more advanced technique: `ret2dlresolve`.

## What ret2dlresolve Means Here

ELF binaries rely on the dynamic linker to resolve imported functions at runtime. If you can control execution and present the linker with forged relocation metadata, you can trick it into resolving a function that the program did not originally import.

In this challenge, the target function is `system`, and the desired command is:

```bash
cat flag.txt
```

So the overall idea is:

1. Overflow the stack.
2. Use a small ROP chain to call `read` again.
3. Place a second-stage forged relocation/symbol blob into memory.
4. Jump through the dynamic resolver trampoline.
5. Resolve `system` on demand.
6. Execute `system("cat flag.txt")`.

## Why This Challenge Is Educational

The important lesson is that dynamic linking metadata is part of the attack surface. A binary can look too small to exploit in the usual ways and still be completely solvable once you understand `plt0`, relocation entries, and symbol resolution.

This challenge is a strong exercise if you are moving beyond beginner ret2win problems and into loader-aware exploitation.

## Manual Analysis Commands

If you want to reconstruct the logic by hand, these commands are useful:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Void"
checksec --file=challenge/void
readelf -r challenge/void
readelf -s challenge/void
objdump -d -Mintel challenge/void | less
ROPgadget --binary challenge/void | head -100
```

What you want to identify:

- the exact overflow offset
- a gadget for `pop rdi`
- a gadget for `pop rsi; pop r15; ret`
- the `read@plt` entry
- the resolver trampoline in the PLT
- a writable memory region for the second-stage blob

## How The Saved archived notes Is Structured

The archived notes in this folder preserve two payloads:

- `stage1`: the initial overflow and primary ROP chain
- `stage2`: the forged `ret2dlresolve` data used to resolve `system`

That design keeps the script portable. You do not need `pwntools` at runtime, because the exploit already embeds the final bytes that were generated from the local challenge binary.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Void"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `HTB{pwnt00l5_h0mep4g3_15_u54ful}`

## Study Notes

This challenge is especially valuable if you want practice with:

- precise stack offset calculation
- small import-table binaries
- PLT and GOT internals
- the dynamic loader as an exploitation primitive

The best learning path is to step through the loader-related entries with `readelf` and `objdump` until the second-stage payload structure makes sense. The archived notes are only a reference after that analysis.
