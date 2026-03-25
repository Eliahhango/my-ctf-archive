#!/usr/bin/env bash

set -euo pipefail

# Challenge: It's Oops PM
# Category: Hardware
# Platform: Hack The Box CTF Try Out
#
# Files provided:
#   - encryption.vhdl
#   - backdoor.vhdl
#   - key.vhdl
#   - tpm.vhdl
#   - schematic.png
#
# Core idea:
# This is a hardware backdoor challenge. Instead of "breaking" the encryption,
# we read the HDL and notice a hidden trigger value that makes the chip leak the
# secret key directly.
#
# What the VHDL tells us:
#
# 1. key.vhdl hardcodes the key:
#      0110001111100001
#
# 2. encryption.vhdl mostly does:
#      E(i) = D(i) XOR K(i)
#    except bits 0, 6, and 13, which are forced to NOT K(bit).
#
# 3. backdoor.vhdl defines a special 16-bit input pattern:
#      1111111111101001
#
# 4. tpm.vhdl wires everything together:
#      - If Data equals the backdoor pattern, Output becomes the raw key
#      - Otherwise Output becomes the encrypted value
#
# So the intended attack is:
#   - Send the exact backdoor pattern to the live service
#   - The service reveals the secret key instead of a normal encrypted output
#   - The service then prints the flag
#
# Real-world lesson:
# Secure hardware can fail completely when a hidden debug/backdoor path is left
# in production logic. Strong encryption does not matter if a privileged bypass
# can dump the key directly.
#
# Manual reproduction:
#   1. Connect:
#        nc 154.57.164.72 31978
#
#   2. Send the backdoor trigger:
#        1111111111101001
#
#   3. Observe:
#        Output: 0110001111100001
#        You triggered the backdoor here is the flag: ...
#
# Flag obtained on this instance:
# HTB{4_7yp1c41_53cu23_TPM_ch1p}

HOST="${1:-154.57.164.72}"
PORT="${2:-31978}"
TRIGGER="1111111111101001"

python3 - "$HOST" "$PORT" "$TRIGGER" <<'PY'
import re
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])
trigger = sys.argv[3]

s = socket.socket()
s.settimeout(5)
s.connect((host, port))

# Read the prompt, then send the 16-bit backdoor trigger.
_ = s.recv(4096)
s.sendall((trigger + "\n").encode())

response = b""
try:
    while True:
        chunk = s.recv(4096)
        if not chunk:
            break
        response += chunk
except Exception:
    pass
finally:
    s.close()

text = response.decode("latin1", "ignore")
match = re.search(r"HTB\{[^}]+\}", text)
if not match:
    print(text)
    raise SystemExit(1)

print(match.group(0))
PY
