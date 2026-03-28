#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: Get Started
# Category: Crypto
# Platform: HackIT
# Points: 50
#
# Prompt:
# "My friend sent me this message, can you decipher it for me ?
# R29Te1dlbGNvbWVfdG9fc2l0ZSF9"
#
# Given hint:
# Flag format: GoH{flag}
#
# Core lesson:
# Recognize common encodings before assuming stronger encryption. Strings made
# of A-Z, a-z, 0-9, +, / and optional = padding are often Base64.
#
# Solve idea:
# 1. Base64-decode the provided string.
# 2. Observe that it becomes GoS{Welcome_to_site!}.
# 3. Normalize the wrapper to the stated platform format GoH{...}.
#
# Expected submission:
# GoH{Welcome_to_site!}

python3 - <<'PY'
import base64

ciphertext = "R29Te1dlbGNvbWVfdG9fc2l0ZSF9"
decoded = base64.b64decode(ciphertext).decode()

prefix, body = decoded.split("{", 1)
body = body[:-1]

print(f"Decoded message: {decoded}")
print(f"Submission flag: GoH{{{body}}}")
PY
