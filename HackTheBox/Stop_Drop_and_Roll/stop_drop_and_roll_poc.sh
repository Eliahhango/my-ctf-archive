#!/usr/bin/env bash

set -euo pipefail

# Challenge: Stop Drop and Roll
# Platform: Hack The Box
# Category: Misc / Scripting
#
# Remote target used during solve:
#   154.57.164.80:31379
#
# Challenge behavior:
# The service presents one or more hazards chosen from:
#   - GORGE  -> STOP
#   - PHREAK -> DROP
#   - FIRE   -> ROLL
#
# When multiple hazards are printed on one line, the required response is the
# mapped actions joined with '-' in the same order.
#
# Example:
#   GORGE, FIRE, PHREAK
# becomes:
#   STOP-ROLL-DROP
#
# Solve strategy:
# 1. Connect to the service.
# 2. Send 'y' to start the game.
# 3. Read each prompt ending in 'What do you do? '.
# 4. Parse the scenario line immediately before that prompt.
# 5. Map hazards to actions and reply fast enough for every round.
# 6. Repeat for 500 rounds.
# 7. Stop once the service returns the flag.
#
# Final flag obtained during testing:
#   HTB{1_wiLl_sT0p_dR0p_4nD_r0Ll_mY_w4Y_oUt!}

host="${1:-154.57.164.80}"
port="${2:-31379}"

python3 - "$host" "$port" <<'PY'
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])

mapping = {
    "GORGE": "STOP",
    "PHREAK": "DROP",
    "FIRE": "ROLL",
}

with socket.create_connection((host, port), timeout=5) as sock:
    sock.settimeout(5)

    banner = b""
    while b"(y/n)" not in banner:
        chunk = sock.recv(4096)
        if not chunk:
            raise SystemExit("[-] Connection closed before the start prompt.")
        banner += chunk

    sock.sendall(b"y\n")

    buffer = b""
    while True:
        chunk = sock.recv(4096)
        if not chunk:
            raise SystemExit("[-] Connection closed before a flag was returned.")

        buffer += chunk
        text = buffer.decode("latin-1", errors="ignore")

        if "HTB{" in text:
            start = text.index("HTB{")
            end = text.find("}", start)
            if end == -1:
                raise SystemExit("[-] Flag start found, but closing brace missing.")
            print(text[start:end + 1])
            break

        prompt = "What do you do? "
        while prompt in text:
            prefix, remainder = text.split(prompt, 1)
            lines = [line.strip() for line in prefix.splitlines() if line.strip()]
            if not lines:
                raise SystemExit("[-] Failed to locate scenario line before prompt.")

            scenario_line = lines[-1]
            hazards = [item.strip() for item in scenario_line.split(",")]

            try:
                response = "-".join(mapping[item] for item in hazards)
            except KeyError as exc:
                raise SystemExit(f"[-] Unexpected hazard: {exc.args[0]}")

            sock.sendall(response.encode() + b"\n")

            buffer = remainder.encode("latin-1", errors="ignore")
            text = remainder
PY
