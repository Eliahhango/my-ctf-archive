#!/usr/bin/env bash

set -euo pipefail

# Challenge: TunnelMadness
# Platform: Hack The Box
# Category: Reversing
#
# Scenario summary:
# Within Vault 8707 are located master keys used to access any vault in the
# country. Unfortunately, the entrance was caved in long ago. There are decades
# old rumors that the few survivors managed to tunnel out deep underground and
# make their way to safety. Can you uncover their tunnel and break back into
# the vault?
#
# Provided files:
#   - rev_tunnelmadness.zip
#   - rev_tunnelmadness/tunnel
#
# Reversing summary:
# The binary stores a 20x20x20 maze directly in .rodata. Each cell is a
# 16-byte struct:
#   { x, y, z, type }
#
# Cell types:
#   0 = start
#   1 = open
#   2 = wall
#   3 = goal
#
# The local binary contains a fake /flag.txt string, so the correct route must
# be replayed against the spawned remote instance to retrieve the real flag.
#
# Command mapping recovered from the binary:
#   - B = x-
#   - R = x+
#   - L = y-
#   - F = y+
#   - D = z-
#   - U = z+
#
# Shortest valid route:
#   UUURFURURRFRRFFUUFURRUFUFFRFUFUUUUFFRRUUUFURFDFFUFFRRRRRFRR
#
# Final flag obtained during testing:
#   HTB{tunn3l1ng_ab0ut_in_3d_039967cc445d165235016bfd180b3d55}

host="${1:-154.57.164.78}"
port="${2:-31567}"

python3 - "$host" "$port" <<'PY'
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])
path = "UUURFURURRFRRFFUUFURRUFUFFRFUFUUUUFFRRUUUFURFDFFUFFRRRRRFRR"

with socket.create_connection((host, port), timeout=5) as sock:
    sock.settimeout(3)

    banner = b""
    while b"Direction (L/R/F/B/U/D/Q)? " not in banner:
        chunk = sock.recv(4096)
        if not chunk:
            raise SystemExit("[-] Connection closed before the first prompt.")
        banner += chunk

    sock.sendall(("\n".join(path) + "\n").encode())

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
    raise SystemExit("[-] Flag not found in remote response.")

start = text.index(marker)
end = text.find("}", start)
if end == -1:
    raise SystemExit("[-] Flag start found, but closing brace missing.")

print(text[start:end + 1])
PY
