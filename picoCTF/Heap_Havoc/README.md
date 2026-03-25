# Heap Havoc

## Overview

This directory contains the local materials and saved solve workflow for the `Heap Havoc` challenge from `picoCTF 2026`. This is a binary exploitation challenge where the challenge text tries to frame the bug as a stack problem, but the real vulnerability is a heap overflow. That mismatch is part of what makes the challenge useful: it rewards trusting the source code and memory layout rather than the surrounding story.

The exploit works by overflowing one heap-allocated name buffer into the next heap object, rewriting a function pointer so the program jumps into the hidden `winner()` routine.

## Challenge Profile

- Challenge: `Heap Havoc`
- Category: `Binary Exploitation`
- Collection: `picoCTF`
- Event or Platform: `picoCTF 2026`
- Difficulty: `Medium`
- Author: `YAHAYA MEDDY`
- Saved PoC: `heap_havoc_poc.sh`

## Directory Contents

- `flag.txt`
- `heap_havoc_poc.sh`
- `vuln`
- `vuln.c`

## First Commands To Run

Start by reading the source and the saved exploit notes:

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Heap_Havoc"
ls -lah
sed -n '1,220p' vuln.c
sed -n "1,260p" "heap_havoc_poc.sh"
```

Run the PoC:

```bash
chmod +x "heap_havoc_poc.sh"
./heap_havoc_poc.sh
```

To reuse it against a fresh remote instance:

```bash
./heap_havoc_poc.sh <HOST> <PORT>
```

## Why The Challenge Description Is Misleading

The prompt talks about overwriting a saved return address, which suggests a classic stack smash. The source code shows something else. The real bug is:

- two `malloc(8)` name buffers
- two `strcpy()` calls
- no length validation

That means the attacker controls a heap write past the end of the first allocation, not a direct stack overwrite.

This is the first important lesson of the challenge: when the narrative and the code disagree, believe the code.

## Memory Layout And Exploit Idea

The vulnerable program allocates:

1. the first struct
2. the first name buffer
3. the second struct
4. the second name buffer

Because the allocations are small and adjacent, overflowing the first name buffer lets the attacker corrupt fields inside the second struct, including:

- `i2->name`
- `i2->callback`

The end goal is:

1. replace `i2->name` with a valid writable address so the program does not crash on the second `strcpy()`
2. replace `i2->callback` with the address of `winner()`

After that, when the program later checks and calls the callback pointer, it jumps into the flag-printing helper.

## Why The Writable Pointer Matters

This is the detail that makes the exploit clean rather than fragile. A naive overwrite that only changes the callback pointer usually fails, because the program still performs:

```c
strcpy(i2->name, argv[2]);
```

If `i2->name` has already been corrupted into an invalid pointer, the process crashes before the callback is reached.

That is why the exploit first redirects `i2->name` into a safe writable location, such as `.bss`, and only then replaces the callback pointer with `winner()`.

This is a strong exploit-development lesson: the target must survive long enough to reach the final control-flow hijack.

## Manual Analysis Workflow

If you want to inspect the binary manually, use:

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Heap_Havoc"
file vuln
objdump -d -Mintel vuln | less
objdump -d vuln | sed -n '/<winner>:/,/^$/p'
objdump -h vuln
```

For debugger work:

```bash
gdb -q ./vuln
```

What you want to confirm:

- the size and order of heap allocations
- the exact offset from `i1->name` to `i2->callback`
- the address of `winner()`
- a writable memory location with no bad bytes for `argv`

## Exploit Structure

The saved exploit uses:

- padding to fill the first name allocation
- more bytes to move across the gap into the second struct
- a safe `.bss` address for `i2->name`
- the `winner()` address for `i2->callback`

Then it sends a harmless second argument so the second `strcpy()` succeeds and the program reaches the callback call.

## Reproduction Commands

Use this sequence for the fast path:

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Heap_Havoc"
sed -n '1,220p' vuln.c
sed -n "1,260p" "heap_havoc_poc.sh"
bash "heap_havoc_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are practicing heap corruption and exploit reliability. It is especially useful as a reminder that successful memory corruption is not just about gaining a write primitive, but about preserving enough program stability to reach the point where that corruption becomes useful.
