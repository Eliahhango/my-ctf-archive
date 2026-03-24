#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: bytemancy 1
# Category: General Skills
# Difficulty: Medium
# Event: picoCTF 2026
# Author: LT 'SYREAL' JONES
#
# Description:
# "Can you conjure the right bytes? The program's source code can be downloaded
# here. Connect to the program with netcat."
#
# Given information from the challenge:
# Source file: app.py
# Remote service: nc foggy-cliff.picoctf.net 65487
#
# Core lesson:
# When a challenge gives you source code, trust the code more than the text
# banner. User-facing prompts can be misleading on purpose, but code shows what
# is actually checked.
#
# Real-world analogy:
# In security work, this is similar to reviewing a web form that says:
# "Enter your employee ID"
# while the backend actually validates something totally different.
#
# If we only trust the UI text, we may solve the wrong problem.
# If we inspect the backend logic, we learn what the system really expects.
#
# Step 1: Read the source code.
# Manual command:
# sed -n '1,220p' app.py
#
# What the important line says:
# if user_input == "\x65" * 1751:
#
# Why this matters:
# The challenge banner says:
# "Send me ASCII DECIMAL 101 1751 times, side-by-side, no space."
#
# That wording tempts you to think the answer is:
# 101101101101...
#
# But the code does not compare against the string "101" repeated.
# It compares against:
# "\x65" * 1751
#
# In Python, \x65 is hexadecimal notation for one byte:
# 0x65
#
# 0x65 is decimal 101
# 0x65 is ASCII 'e'
#
# So the program really wants:
# lowercase letter e
# repeated 1751 times
#
# Step 2: Understand the representation mismatch.
# Manual concept:
# decimal 101  -> byte value 101
# byte value 101 -> hex 0x65
# hex 0x65 -> ASCII character 'e'
#
# Why this matters:
# The prompt talks about "ASCII DECIMAL 101", but the code compares characters,
# not the text digits '1', '0', and '1'.
#
# This is a common security and programming idea:
# the same value can appear in multiple representations:
# - decimal
# - hexadecimal
# - raw byte
# - printable character
#
# Many bugs and challenge tricks come from confusing representation with value.
#
# Real-world example:
# A firewall may log a byte as 0x2e, a parser may treat it as '.', and a report
# may display it as decimal 46. These are three ways to describe the same byte.
#
# Step 3: Build the exact payload.
# Manual command:
# python3 - <<'PY'
# print('e' * 1751)
# PY
#
# Why this matters:
# Sending the exact length is critical.
# If we send too few or too many characters, the equality check fails.
#
# Step 4: Send the payload to the remote service.
# Manual command:
# python3 - <<'PY'
# import socket
# payload = b'e' * 1751 + b'\n'
# with socket.create_connection(('foggy-cliff.picoctf.net', 65487)) as s:
#     s.recv(4096)
#     s.sendall(payload)
#     print(s.recv(4096).decode())
# PY
#
# Why this matters:
# Using Python avoids counting mistakes that can happen when pasting a very long
# string by hand.
#
# Real-world lesson:
# Automation improves reliability.
# In incident response, exploit development, and scripting, exact byte counts
# matter. Generating input programmatically is safer than manual typing.
#
# Step 5: Read the flag.
# Result:
# The server returns the flag once it receives exactly 1751 lowercase e bytes.
#
# Flag obtained:
# picoCTF{h0w_m4ny_e's???_0c1ad83a}

python3 - <<'PY'
import re
import socket

host = "foggy-cliff.picoctf.net"
port = 65487
payload = b"e" * 1751 + b"\n"

with socket.create_connection((host, port), timeout=10) as s:
    s.recv(4096)
    s.sendall(payload)

    response = b""
    while True:
        try:
            chunk = s.recv(4096)
        except socket.timeout:
            break
        if not chunk:
            break
        response += chunk
        if b"picoCTF{" in response:
            break

match = re.search(rb"picoCTF\{[^}]+\}", response)
if not match:
    raise SystemExit("Flag not found in the server response.")

print(match.group(0).decode())
PY
