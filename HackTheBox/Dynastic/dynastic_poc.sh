#!/usr/bin/env bash

set -euo pipefail

# Challenge: Dynastic
# Platform: Hack The Box
# Category: Crypto
#
# Full scenario:
# You find yourself trapped inside a sealed gas chamber, and suddenly, the air
# is pierced by the sound of a distorted voice played through a pre-recorded
# tape. Through this eerie transmission, you discover that within the next
# 15 minutes, this very chamber will be inundated with lethal hydrogen
# cyanide. As the tape's message concludes, a sudden mechanical whirring fills
# the chamber, followed by the ominous ticking of a clock. You realise that
# each beat is one step closer to death. Darkness envelops you, your right
# hand restrained by handcuffs, and the exit door is locked. Your situation
# deteriorates as you realise that both the door and the handcuffs demand the
# same passcode to unlock. Panic is a luxury you cannot afford; swift action is
# imperative. As you explore your surroundings, your trembling fingers
# encounter a torch. Instantly, upon flipping the switch, the chamber is
# bathed in a dim glow, unveiling cryptic letters etched into the walls and a
# disturbing image of a Roman emperor drawn in blood. Decrypting the letters
# will provide you the key required to unlock the locks. Use the torch wisely
# as its battery is almost drained out!
#
# Provided files:
#   - crypto_dynastic.zip
#   - crypto_dynastic/source.py
#   - crypto_dynastic/output.txt
#
# Challenge summary:
# The encryption shifts each alphabetic character forward by its position index
# in the string. Non-alphabetic characters are left unchanged.
#
# If encryption is:
#   ciphertext[i] = plaintext[i] + i (mod 26)
#
# Then decryption is:
#   plaintext[i] = ciphertext[i] - i (mod 26)
#
# Final flag obtained during testing:
#   HTB{DID_YOU_KNOW_ABOUT_THE_TRITHEMIUS_CIPHER?!_IT_IS_SIMILAR_TO_CAESAR_CIPHER}

python3 - <<'PY'
from pathlib import Path

output_path = Path("/home/eliah/Desktop/CTF/HackTheBox/Dynastic/crypto_dynastic/output.txt")
lines = output_path.read_text().splitlines()
ciphertext = lines[-1].strip()

plaintext = []
for i, ch in enumerate(ciphertext):
    if ch.isalpha():
        val = (ord(ch) - ord("A") - i) % 26
        plaintext.append(chr(val + ord("A")))
    else:
        plaintext.append(ch)

message = "".join(plaintext)
print(f"HTB{{{message}}}")
PY
