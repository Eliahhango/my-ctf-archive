#!/usr/bin/env bash

set -euo pipefail

# Challenge: An unusual sighting
# Platform: Hack The Box
# Category: Forensics
#
# Remote target used during solve:
#   154.57.164.83:31920
#
# Challenge summary:
# The service asks a fixed sequence of forensic questions based on two files:
# SSH logs and Bash history from a compromised development server.
#
# Key findings:
#   - SSH server: 100.107.36.130:2221
#   - First successful login: 2024-02-13 11:29:50
#   - Unusual login time: 2024-02-19 04:00:14
#   - Attacker public key fingerprint:
#       OPkBSs6okUKraq8pYo4XwwBg55QSo210F09FCe1-yj4
#   - First command after login: whoami
#   - Final command before logout: ./setup
#
# Final flag obtained during testing:
#   HTB{4n_unusual_s1ght1ng_1n_SSH_l0gs!}
#
# Note:
# The provided download link returned an HTB 500 error during this session, so
# this solve script reproduces the successful remote interaction directly.

host="${1:-154.57.164.83}"
port="${2:-31920}"

python3 - "$host" "$port" <<'PY'
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])

answers = [
    "100.107.36.130:2221",
    "2024-02-13 11:29:50",
    "2024-02-19 04:00:14",
    "OPkBSs6okUKraq8pYo4XwwBg55QSo210F09FCe1-yj4",
    "whoami",
    "./setup",
]

with socket.create_connection((host, port), timeout=5) as sock:
    sock.settimeout(5)
    buffer = b""

    for answer in answers:
        while b"> " not in buffer:
            chunk = sock.recv(4096)
            if not chunk:
                raise SystemExit("[-] Connection closed before the next prompt.")
            buffer += chunk

        sock.sendall(answer.encode() + b"\n")
        buffer = b""

    output = b""
    while True:
        try:
            chunk = sock.recv(4096)
        except socket.timeout:
            break
        if not chunk:
            break
        output += chunk

text = output.decode("latin-1", errors="ignore")
marker = "HTB{"
if marker not in text:
    raise SystemExit("[-] Flag not found in service response.")

start = text.index(marker)
end = text.find("}", start)
if end == -1:
    raise SystemExit("[-] Flag start found, but closing brace missing.")

print(text[start:end + 1])
PY
