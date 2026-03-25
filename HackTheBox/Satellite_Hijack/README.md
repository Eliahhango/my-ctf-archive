# Satellite Hijack

## Overview

This directory contains the local materials and saved solve workflow for the `Satellite Hijack` challenge on Hack The Box. This is a reversing challenge built around a shared library that hides its real behavior behind an IFUNC resolver and runtime code patching.

At first glance the binary appears to be a simple terminal program, but the real validation logic is buried inside `library.so`. The important task is to recover that hidden logic and reconstruct the expected flag body statically.

## Challenge Profile

- Challenge: `Satellite Hijack`
- Category: `Reversing`
- Platform: `Hack The Box`
- Saved PoC: `satellite_hijack_poc.sh`

## Directory Contents

- `rev_satellitehijack/`
- `rev_satellitehijack.zip`
- `satellite_hijack_poc.sh`

## First Commands To Run

Start by reviewing the local files:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Satellite_Hijack"
ls -lah
unzip -l "rev_satellitehijack.zip"
file rev_satellitehijack/satellite rev_satellitehijack/library.so
```

Read the saved PoC:

```bash
sed -n "1,220p" "satellite_hijack_poc.sh"
```

Run it:

```bash
chmod +x "satellite_hijack_poc.sh"
./satellite_hijack_poc.sh
```

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

The saved PoC solves this correctly by rebuilding the stack layout exactly, extracting the first `0x1c` bytes, and then reversing the XOR-by-index transformation.

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

## Reproduction Commands

Use this sequence for a clean reproduction:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Satellite_Hijack"
unzip -l "rev_satellitehijack.zip"
sed -n "1,220p" "satellite_hijack_poc.sh"
bash "satellite_hijack_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you want practice with:

- IFUNC-based indirection
- shared-library reversing
- runtime patching of GOT targets
- decoding hidden validation logic statically

It is especially useful as a reminder that the obvious exported function is not always where the real security logic lives.
