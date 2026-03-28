#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: Welcome
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
# Test common encodings early. This string is standard Base64 and decodes
# directly into a readable flag-like message.
#
# Solve idea:
# 1. Base64-decode the provided string.
# 2. Observe that it becomes GoS{Welcome_to_site!}.
# 3. Normalize the wrapper to the stated accepted platform format GoH{...}.
#
# Expected submission:
# GoH{Welcome_to_site!}

python3 - <<'PY'
import base64

ciphertext = "R29Te1dlbGNvbWVfdG9fc2l0ZSF9"
decoded = base64.b64decode(ciphertext).decode()
_, body = decoded.split("{", 1)
body = body[:-1]

print(f"Decoded message: {decoded}")
print(f"Submission flag: GoH{{{body}}}")
PY
