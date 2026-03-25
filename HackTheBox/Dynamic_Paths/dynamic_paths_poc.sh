#!/usr/bin/env bash

set -euo pipefail

# Challenge: Dynamic Paths
# Platform: Hack The Box
# Category: Coding / Algorithms
#
# Full scenario:
# On your way to the vault, you decide to follow the underground tunnels, a
# vast and complicated network of paths used by early humans before the great
# war. From your previous hack, you already have a map of the tunnels, along
# with information like distances between sections of the tunnels. While you
# were studying it to figure your path, a wild super mutant behemoth came
# behind you and started attacking. Without a second thought, you run into the
# tunnel, but the behemoth came running inside as well. Can you use your
# extensive knowledge of the underground tunnels to reach your destination fast
# and outrun the behemoth?
#
# Remote target used during solve:
#   154.57.164.83:32052
#
# Challenge behavior:
# The service gives 100 grids. For each one, we must compute the minimum path
# sum from the top-left cell to the bottom-right cell while moving only right
# or down.
#
# Solve strategy:
# Use dynamic programming:
#   dp[c] = minimum cost to reach column c in the current row
#
# Transition:
#   dp[c] = min(dp[c], dp[c-1]) + grid[r][c]
#
# Final flag obtained during testing:
#   HTB{b3h3M07H_5h0uld_H4v3_57ud13D_dYM4m1C_pr09r4mm1n9_70_C47ch_y0u_f25c7d6602463cccd4db4227827c9436}

host="${1:-154.57.164.83}"
port="${2:-32052}"

python3 -u - "$host" "$port" <<'PY'
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])


def min_path_sum(rows, cols, values):
    dp = [0] * cols
    idx = 0
    for r in range(rows):
        for c in range(cols):
            val = values[idx]
            idx += 1
            if r == 0 and c == 0:
                dp[c] = val
            elif r == 0:
                dp[c] = dp[c - 1] + val
            elif c == 0:
                dp[c] = dp[c] + val
            else:
                dp[c] = min(dp[c], dp[c - 1]) + val
    return dp[-1]


with socket.create_connection((host, port), timeout=10) as sock:
    sock.settimeout(10)
    buffer = b""
    solved = 0

    while True:
        chunk = sock.recv(4096)
        if not chunk:
            raise SystemExit("[-] Connection closed before the flag was returned.")

        buffer += chunk
        text = buffer.decode("latin-1", errors="ignore")

        if "HTB{" in text:
            start = text.index("HTB{")
            end = text.find("}", start)
            if end == -1:
                raise SystemExit("[-] Flag start found, but closing brace missing.")
            print(text[start:end + 1])
            break

        prompt = "\n> "
        while prompt in text:
            prefix, remainder = text.split(prompt, 1)
            lines = [line.strip() for line in prefix.splitlines() if line.strip()]

            dims = None
            values = None
            for i in range(len(lines) - 1):
                parts = lines[i].split()
                if len(parts) == 2 and all(part.isdigit() for part in parts):
                    candidate_values = lines[i + 1].split()
                    if candidate_values and all(part.isdigit() for part in candidate_values):
                        dims = tuple(map(int, parts))
                        values = list(map(int, candidate_values))

            if dims is None or values is None:
                raise SystemExit("[-] Failed to parse grid prompt.")

            rows, cols = dims
            answer = min_path_sum(rows, cols, values)
            solved += 1
            sock.sendall(f"{answer}\n".encode())

            buffer = remainder.encode("latin-1", errors="ignore")
            text = remainder
PY
