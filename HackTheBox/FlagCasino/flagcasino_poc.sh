#!/usr/bin/env bash

set -euo pipefail

# Challenge: FlagCasino
# Platform: Hack The Box
# Category: Reversing
#
# Full scenario:
# The team stumbles into a long-abandoned casino. As you enter, the lights and
# music whir to life, and a staff of robots begin moving around and offering
# games, while skeletons of prewar patrons are slumped at slot machines. A
# robotic dealer waves you over and promises great wealth if you can win - can
# you beat the house and gather funds for the mission?
#
# Provided files:
#   - rev_flagcasino.zip
#   - rev_flagcasino/casino
#
# Reversing summary:
# The binary loops 29 times. Each round:
#   1. reads one byte
#   2. seeds libc rand() with srand(input_byte)
#   3. compares the first rand() output against check[i]
#
# Because srand() is reset every round with a single-byte seed, we can brute
# force each table entry independently over all 256 possible byte values.
#
# Final flag obtained during testing:
#   HTB{r4nd_1s_v3ry_pr3d1ct4bl3}

python3 - <<'PY'
import ctypes
import struct
from pathlib import Path

binary_path = Path("/home/eliah/Desktop/CTF/HackTheBox/FlagCasino/rev_flagcasino/casino")
binary = binary_path.read_bytes()

# From the binary:
#   .data file offset = 0x3060
#   check table vaddr = 0x4080
# So the file offset of the table is 0x3080.
table_offset = 0x3080
table_len = 29
table = struct.unpack("<29I", binary[table_offset:table_offset + table_len * 4])

libc = ctypes.CDLL("libc.so.6")
result = []

for target in table:
    match = None
    for candidate in range(256):
        libc.srand(candidate)
        if (libc.rand() & 0xFFFFFFFF) == target:
            match = candidate
            break
    if match is None:
        raise SystemExit(f"[-] No seed found for table entry {target:#x}")
    result.append(match)

print(bytes(result).decode())
PY
