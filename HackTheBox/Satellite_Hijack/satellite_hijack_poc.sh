#!/usr/bin/env bash
set -euo pipefail

# Hack The Box - Satellite Hijack
#
# The crew has located a dilapidated pre-war bunker. Deep within, a dusty
# control panel reveals that it was once used for communication with a
# low-orbit observation satellite. During the war, actors on all sides
# infiltrated and hacked each other's systems and software, inserting
# backdoors to cripple or take control of critical machinery. It seems like
# this panel has been tampered with to prevent the control codes necessary to
# operate the satellite from being transmitted. Recover the codes and take
# control of the satellite to locate the enemy factions.
#
# Solve notes:
# - `satellite` loads `library.so` and resolves `send_satellite_message`
#   through an IFUNC resolver.
# - If the hidden environment variable `SAT_PROD_ENVIRONRONMENT` is present,
#   the resolver patches the main binary's `read@GOT` entry with a memfrob'd
#   hidden routine copied out of `library.so`.
# - That routine scans the terminal input for `HTB{` and validates the next
#   28 bytes with `candidate[i] ^ key[i] == i`.
# - Reconstructing the overlapped stack key constants yields the flag body
#   directly.

python3 - <<'PY'
import struct
from pathlib import Path

lib = Path("/home/eliah/Desktop/CTF/HackTheBox/Satellite_Hijack/rev_satellitehijack/library.so").read_bytes()

stack = bytearray(b"\x00" * 0x40)
base = 0x28
for off, val in [
    (-0x28, 0x37593076307B356C),
    (-0x20, 0x3A7C3E753F665666),
    (-0x1B, 0x784C7C214F3A7C3E),
    (-0x13, 0x00663B2C6A246F21),
]:
    idx = base + off
    stack[idx:idx + 8] = struct.pack("<Q", val)

key = bytes(stack[:0x1C])
inside = "".join(chr(b ^ i) for i, b in enumerate(key))
print("HTB{" + inside)
PY
