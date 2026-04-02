#!/usr/bin/env bash
set -euo pipefail

: <<'OVERVIEW'
Phantom Recursion PoC
---------------------
This script follows three extraction stages:
1) Read obvious embedded values (`_t` and `_h`).
2) Decode `_h` with XOR 0xAA (known decoy output).
3) Derive a code-path candidate from source structure:
   - line lengths
   - adjacent length sums
   - XOR with 0x58
   - regex extraction for snf{...}

Step-by-step commands:
  cd /home/eliah/Desktop/CTF/CTFZone/Phantom_Recursion
  chmod +x phantom_recursion_poc.sh
  ./phantom_recursion_poc.sh
OVERVIEW

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
challenge="$script_dir/challenge.py"

: <<'STEP1'
STEP 1: Inspect embedded breadcrumbs
- Executes challenge.py in an isolated namespace.
- Prints:
  - _t decoded as text
  - _h raw bytes as hex
STEP1
echo "[1/3] Inspect the embedded breadcrumbs"
python3 - <<'PY' "$challenge"
from pathlib import Path
import sys

challenge = Path(sys.argv[1])
ns = {}
exec(challenge.read_text(), ns)

print("t_blob =", bytes(ns["_t"]).decode())
print("h_blob =", ns["_h"]().hex())
PY

: <<'STEP2'
STEP 2: Decode the decoy instruction string
- XOR every byte from _h() with 0xAA.
- Shows the instruction text embedded by the author.
STEP2
echo
echo "[2/3] Decode the hidden instruction string"
python3 - <<'PY' "$challenge"
from pathlib import Path
import sys

challenge = Path(sys.argv[1])
ns = {}
exec(challenge.read_text(), ns)

plain = bytes(c ^ 0xaa for c in ns["_h"]()).decode()
print(plain)
PY

: <<'STEP3'
STEP 3: Structural extraction candidate
- Build `line_len` from challenge.py source lines.
- Build `sum_adj` from adjacent line lengths.
- XOR each byte with 0x58.
- Project to printable characters and extract `snf{...}`.
STEP3
echo
echo "[3/3] Derive the code-path candidate flag"
python3 - <<'PY' "$challenge"
from pathlib import Path
import re
import sys

challenge = Path(sys.argv[1])
lines = challenge.read_text().splitlines()

line_len = [len(line) & 0xFF for line in lines]
sum_adj = [((line_len[i] + line_len[i + 1]) & 0xFF) for i in range(len(line_len) - 1)]
decoded = bytes(v ^ 0x58 for v in sum_adj)
projected = bytes(v if 32 <= v < 127 else ord(".") for v in decoded)

print("stream =", projected.decode())

token = None
for data in (decoded, projected):
    m = re.search(rb"snf\{[ -~]{1,120}?\}", data)
    if m:
        token = m.group().decode()
        break

if token is None:
    raise SystemExit("No snf{...} token recovered")

print("candidate =", token)
PY
