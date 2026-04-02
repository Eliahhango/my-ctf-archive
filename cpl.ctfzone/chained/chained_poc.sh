#!/usr/bin/env bash
set -euo pipefail

# Challenge: chained
# Platform: cpl.ctfzone
# Category: crypto
# Points: 300
# Author: erickalex
#
# Solve sketch:
# 1. Strip non-Base64 separators.
# 2. Base64-decode the cleaned payload.
# 3. Use the visible flag prefix `snf{` as a crib to recover a 4-byte
#    repeating XOR key for the decoded layer.
# 4. Print the decrypted stream and the printable body candidate.

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

SCRIPT_DIR="$script_dir" python3 - <<'PY'
from pathlib import Path
import base64
import os

text = (Path(os.environ["SCRIPT_DIR"]) / "challenge.txt").read_text().strip()
base = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

filtered = "".join(c for c in text if c in base)
padded = filtered + "=" * ((4 - len(filtered) % 4) % 4)
decoded = base64.b64decode(padded, validate=True)

# The screenshot shows the `snf{...}` submission prefix.
crib = b"snf{"
key = bytes(decoded[i] ^ crib[i] for i in range(len(crib)))

plaintext = bytes(decoded[i] ^ key[i % len(key)] for i in range(len(decoded)))
visible = "".join(chr(b) if 32 <= b < 127 else "." for b in plaintext)
body = "".join(ch for ch in visible if ch in base)

print("[+] cleaned base64:", filtered)
print("[+] decoded bytes:", decoded.hex())
print("[+] crib key:", key.hex())
print("[+] decrypted stream:", visible)
print("[+] printable body:", body)
print("[+] flag candidate: snf{" + body.removeprefix("snf") + "}")
PY
