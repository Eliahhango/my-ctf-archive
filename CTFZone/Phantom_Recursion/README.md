# Phantom Recursion

## Overview

This challenge is a small Python obfuscation puzzle. Most of the file is
decoy recursion and checksum scaffolding, and the one clearly recoverable byte
string decrypts to an instruction rather than to a directly accepted flag.

## Challenge Profile

- Challenge: `Phantom Recursion`
- Category: `Crypto`
- Difficulty: `HARD`
- Points: `400`
- Author: `DR_PROGRAMMER`

## Directory Contents

- `challenge.py`
- `phantom_recursion_poc.sh`

## Solve Flow

The important clues are `_t` and `_h()`.

1. Inspect the embedded values.
2. Notice `_t` already gives the decoy fragment `snf{not_it`.
3. XOR `_h()` with `0xaa`.
4. The decrypted text is another instruction string, not a verified flag.

## Manual Commands

```bash
cd "/home/eliah/Desktop/CTF/CTFZone/Phantom_Recursion"
python3 - <<'PY'
from pathlib import Path
ns = {}
exec(Path("challenge.py").read_text(), ns)
print(bytes(ns["_t"]).decode())
print(ns["_h"]().hex())
PY
```

```bash
python3 - <<'PY'
from pathlib import Path
ns = {}
exec(Path("challenge.py").read_text(), ns)
plain = bytes(c ^ 0xaa for c in ns["_h"]()).decode()
print(plain)
PY
```

## Verified Extraction

The file directly yields:

`snf{this_is_not_the_flag_use_the_code}`

This string is a decoy instruction and was rejected by the platform.
No final accepted flag has been verified from the local file yet.
