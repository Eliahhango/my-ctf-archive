# Satellite Hijack

## Overview

This directory contains the local materials and manual walkthrough for the `Satellite Hijack` challenge on Hack The Box. This is a reversing challenge built around a shared library that hides its real behavior behind an IFUNC resolver and runtime code patching.

At first glance the binary appears to be a simple terminal program, but the real validation logic is buried inside `library.so`. The important task is to recover that hidden logic and reconstruct the expected flag body statically.

## Challenge Profile

- Challenge: `Satellite Hijack`
- Category: `Reversing`
- Platform: `Hack The Box`

## Directory Contents

- `rev_satellitehijack/`
- `rev_satellitehijack.zip`
- `satellite_hijack_poc.sh`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Satellite_Hijack"
ls -lah
unzip -l "rev_satellitehijack.zip"
```

Useful first inspection commands:

```bash
file 'rev_satellitehijack.zip'
strings -n 5 'rev_satellitehijack.zip' | head -200
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Why This Challenge Is Interesting

The wrapper binary `satellite` is deliberately minimal. The real behavior is delegated to `library.so`, which exports `send_satellite_message` through an IFUNC resolver.

That means the function pointer returned at runtime is not fixed in the normal way. Instead, the library decides what implementation to use, and it can perform extra setup before returning that pointer.

In this challenge, that setup is the real trick.

## Hidden Behavior

When the hidden environment variable `SAT_PROD_ENVIRONRONMENT` is present, the resolver performs extra work:

1. it locates a target pointer in the main binary
2. it copies an obfuscated code blob out of the shared library
3. it decodes that blob with `memfrob`
4. it patches the main binary’s `read@GOT` entry

So instead of calling the normal libc `read`, the main binary begins calling a hidden replacement routine.

This is why the challenge feels strange if you only look at the wrapper program. The meaningful logic is not in the obvious function path at all.

## What The Hidden Routine Does

Once decoded, the replacement routine scans terminal input for the prefix:

```text
HTB{
```

After that, it validates the next 28 bytes using an XOR-by-index relation:

```text
candidate[i] ^ key[i] == i
```

So the remaining task is to recover the exact 28-byte key.

## The Final Reversing Step

The validator does not store the key as one neat string. Instead, it writes overlapping 8-byte immediates onto the stack. That overlap is important. If you reconstruct the bytes naively, you get the wrong result.

The archived notes in this folder rebuild the stack layout exactly, extract the first `0x1c` bytes, and then reverse the XOR-by-index transformation.

That yields the final flag body directly.

## Manual Analysis Commands

If you want to retrace the reversing process yourself, these commands are a useful starting point:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Satellite_Hijack"
objdump -T rev_satellitehijack/library.so
objdump -d -Mintel rev_satellitehijack/library.so | less
strings -n 5 rev_satellitehijack/library.so
radare2 -AA rev_satellitehijack/library.so
```

Useful questions to answer during analysis:

- where is the IFUNC resolver
- how is the hidden environment variable constructed
- what code region is copied and decoded
- what import or GOT entry is patched
- how is the final candidate validated

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Satellite_Hijack"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `HTB{l4y3r5_0n_l4y3r5_0n_l4y3r5!}`

## Study Notes

This challenge is worth revisiting if you want practice with:

- IFUNC-based indirection
- shared-library reversing
- runtime patching of GOT targets
- decoding hidden validation logic statically

It is especially useful as a reminder that the obvious exported function is not always where the real security logic lives.
