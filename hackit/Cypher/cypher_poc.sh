#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: Cypher
# Category: Crypto
# Platform: HackIT
# Points: 50
#
# Prompt:
# "How about bashing this cipher:
# TIS{ZgYzhs_Xrksvi_Prwwl!}"
#
# Core lesson:
# Recognize simple substitution ciphers quickly. The mixed-case string and the
# clue "bashing this cipher" strongly suggest Atbash, where each letter is
# mirrored across the alphabet:
# A <-> Z, B <-> Y, C <-> X, ...
#
# Solve idea:
# The visible text uses `TIS{...}` as part of the puzzle presentation, but the
# platform accepts the final answer with the `GoH{...}` wrapper. Decode only
# the payload inside the braces with Atbash and rebuild the accepted flag.
#
# Expected flag:
# GoH{AtBash_Cipher_Kiddo!}

python3 - <<'PY'
ciphertext = "TIS{ZgYzhs_Xrksvi_Prwwl!}"

def atbash_char(ch: str) -> str:
    if "A" <= ch <= "Z":
        return chr(ord("Z") - (ord(ch) - ord("A")))
    if "a" <= ch <= "z":
        return chr(ord("z") - (ord(ch) - ord("a")))
    return ch

_prefix, body = ciphertext.split("{", 1)
body = body[:-1]
plaintext_body = "".join(atbash_char(ch) for ch in body)
print(f"GoH{{{plaintext_body}}}")
PY
