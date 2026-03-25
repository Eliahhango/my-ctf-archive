#!/usr/bin/env bash

set -euo pipefail

# Challenge: Silicon Data Sleuthing
# Platform: Hack The Box
# Category: Forensics
#
# Remote target used during solve:
#   154.57.164.67:32562
#
# Challenge summary:
# The task revolves around analyzing an extracted OpenWrt firmware image and
# answering fixed questions about the router's configuration.
#
# Recovered answers:
#   - OpenWrt version: 23.05.0
#   - Linux kernel version: 5.15.134
#   - Root password hash:
#       root:$1$YfuRJudo$cXCiIJXn9fWLIt8WY2Okp1:19804:0:99999:7:::
#   - PPPoE username: yohZ5ah
#   - PPPoE password: ae-h+i$i^Ngohroorie!bieng6kee7oh
#   - WiFi SSID: VLT-AP01
#   - WiFi password: french-halves-vehicular-favorable
#   - WAN->LAN forwarded ports: 1778,2289,8088
#
# Final flag obtained during testing:
#   HTB{Y0u'v3_m4st3r3d_0p3nWRT_d4t4_3xtr4ct10n!!_ccc7c86e99701a06e8997bef3acd71f8}
#
# Note:
# The signed HTB download URL returned a 500 Server Error during this session,
# so this script reproduces the successful remote solve directly.

host="${1:-154.57.164.67}"
port="${2:-32562}"

python3 - "$host" "$port" <<'PY'
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])

answers = [
    "23.05.0",
    "5.15.134",
    "root:$1$YfuRJudo$cXCiIJXn9fWLIt8WY2Okp1:19804:0:99999:7:::",
    "yohZ5ah",
    "ae-h+i$i^Ngohroorie!bieng6kee7oh",
    "VLT-AP01",
    "french-halves-vehicular-favorable",
    "1778,2289,8088",
]

with socket.create_connection((host, port), timeout=10) as sock:
    sock.settimeout(15)
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
