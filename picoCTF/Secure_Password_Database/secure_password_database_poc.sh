#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: Secure Password Database
# Category: Reverse Engineering
# Difficulty: Medium
# Event: picoCTF 2026
# Author: PHILIP THAYER
#
# Description:
# I made a new password authentication program that even shows you the password
# you entered saved in the database! Isn't that cool?
#
# Given information:
# File: system.out
# Service: nc candy-mountain.picoctf.net 59219
#
# Solving idea:
# 1. Reverse the local ELF binary to recover how the program builds the secret.
# 2. Extract the hidden bytes from .rodata and undo the XOR with 0xaa.
# 3. Recreate the custom hash() routine.
# 4. Send the resulting decimal hash to the remote service to get the flag.
#
# Step 1: Inspect the main logic.
# Manual command:
# objdump -d -Mintel system.out | sed -n '/<main>:/,/^$/p'
# Reason:
# This shows that main copies bytes from obf_bytes, XORs each byte with 0xaa,
# then calls make_secret() and compares your input to the result of hash().
#
# Step 2: Inspect the helper functions.
# Manual command:
# objdump -d -Mintel system.out | sed -n '/<hash>:/,/^$/p;/<make_secret>:/,/^$/p'
# Reason:
# This reveals the custom hash algorithm:
# hash = (hash * 33) + current_byte
# starting from 0x1505 until the null terminator.
#
# Step 3: Extract the obfuscated bytes.
# Manual command:
# objdump -s -j .rodata system.out | sed -n '1,40p'
# Reason:
# At address 0x2008 the binary stores these bytes:
# c3 ff c8 c2 92 9b 8b c0 80 c2 c4 8b
# XOR each one with 0xaa to recover the secret:
# iUbh81!j*hn!
#
# Step 4: Compute the 64-bit wrapped hash.
# Manual command:
# python3 - <<'PY'
# secret = b'iUbh81!j*hn!'
# h = 0x1505
# for b in secret:
#     h = ((h << 5) + h + b) & ((1 << 64) - 1)
# print(h)
# PY
# Reason:
# The binary uses an unsigned 64-bit return value, so we keep the result wrapped
# to 64 bits. The correct hash is:
# 15237662580160011234
#
# Step 5: Submit the hash to the remote service.
# Manual command:
# printf 'A\n80\n15237662580160011234\n' | nc candy-mountain.picoctf.net 59219
# Reason:
# Any short password works for the leak stage. The final decimal value is what
# the program actually checks before printing the flag.
#
# Flag obtained:
# picoCTF{d0nt_trust_us3rs}

host="candy-mountain.picoctf.net"
port="59219"
secret='iUbh81!j*hn!'

hash_value="$(
python3 - <<'PY'
secret = b'iUbh81!j*hn!'
h = 0x1505
for b in secret:
    h = ((h << 5) + h + b) & ((1 << 64) - 1)
print(h)
PY
)"

printf 'A\n80\n%s\n' "$hash_value" \
  | nc "$host" "$port" \
  | grep -o 'picoCTF{[^}]*}'
