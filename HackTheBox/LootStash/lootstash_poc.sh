#!/usr/bin/env bash

set -euo pipefail

# Challenge: LootStash
# Platform: Hack The Box
# Category: Reversing
#
# Full scenario:
# A giant stash of powerful weapons and gear have been dropped into the arena -
# but there's one item you have in mind. Can you filter through the stack to
# get to the one thing you really need?
#
# Provided files:
#   - rev_lootstash.zip
#   - rev_lootstash/stash
#
# Reversing summary:
# The binary seeds rand() with the current time, picks one index from a large
# static loot table, and prints that single item. The flag itself is stored as
# one of the table entries in the binary, so we can recover it statically
# without relying on timing or repeated execution.
#
# Final flag obtained during testing:
#   HTB{n33dl3_1n_a_l00t_stack}

python3 - <<'PY'
import re
import subprocess

binary = "/home/eliah/Desktop/CTF/HackTheBox/LootStash/rev_lootstash/stash"
output = subprocess.check_output(["strings", "-n", "5", binary], text=True)
match = re.search(r"HTB\{[^}]+\}", output)

if not match:
    raise SystemExit("[-] Flag not found in binary strings output.")

print(match.group(0))
PY
