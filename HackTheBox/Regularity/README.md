# Regularity

## Overview

This directory contains the local materials and saved solve workflow for the `Regularity` challenge on Hack The Box CTF Try Out. This is a binary exploitation challenge with a clean stack overflow and a very convenient jump gadget. The unusual part is that you do not need a stack address leak to run shellcode, because the program already leaves a register pointing at your controlled buffer.

That makes the challenge a strong example of how register state can remove the need for a more complicated exploit chain.

## Challenge Profile

- Challenge: `Regularity`
- Category: `Pwn`
- Platform: `Hack The Box CTF Try Out`
- Saved PoC: `regularity_poc.sh`

## Directory Contents

- `pwn_regularity/`
- `pwn_regularity.zip`
- `regularity_poc.sh`

## First Commands To Run

Start by reviewing the archive and the binary:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Regularity"
ls -lah
unzip -l "pwn_regularity.zip"
file pwn_regularity/regularity
```

Read the saved PoC:

```bash
sed -n "1,220p" "regularity_poc.sh"
```

Run it:

```bash
chmod +x "regularity_poc.sh"
./regularity_poc.sh
```

To reuse it against a fresh spawned target:

```bash
./regularity_poc.sh <HOST> <PORT>
```

## What The Binary Does

The program is minimal:

1. it prints a greeting
2. it reads user input
3. it prints a closing line
4. it exits

The vulnerability is in the custom `read` helper. It allocates `0x100` bytes on the stack but reads `0x110` bytes, so the overflow reaches past the buffer and into the saved return state.

## Why This Challenge Is Nicer Than It First Looks

Many shellcode-overflow problems require a stack leak so the attacker knows where the payload landed. This one avoids that requirement because:

- the input buffer is located at `rsp`
- the program keeps `rsi` pointing at that buffer after `read()` returns
- the binary contains a direct `jmp rsi` gadget at `0x401041`

That means the exploit can simply:

1. place shellcode at the start of the input
2. pad to the return address
3. overwrite RIP with `0x401041`

Execution then jumps directly into the controlled stack buffer.

## Exploit Structure

The saved exploit uses 64-bit shellcode that:

- opens `flag.txt`
- reads the flag contents
- writes them to stdout
- exits

The shellcode is placed at the beginning of the payload. After padding to the saved return address, the exploit writes the `jmp rsi` gadget address.

That is all that is needed.

## Manual Analysis Commands

If you want to inspect the binary manually, these are good commands:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Regularity"
checksec --file=pwn_regularity/regularity
objdump -d -Mintel pwn_regularity/regularity | less
ROPgadget --binary pwn_regularity/regularity | grep 'jmp rsi'
```

What you want to confirm:

- the exact stack allocation size
- the exact read length
- the offset from the buffer to saved RIP
- the existence of `jmp rsi`
- that `rsi` still points at your input when control returns

## Reproduction Commands

Use this sequence for the fast path:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Regularity"
unzip -l "pwn_regularity.zip"
sed -n "1,220p" "regularity_poc.sh"
bash "regularity_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are practicing shellcode-based exploitation. It is especially useful as a reminder that register state after a syscall can matter just as much as the overflow itself. Sometimes the easiest path is not to leak an address, but to reuse a register that already points where you want to go.
