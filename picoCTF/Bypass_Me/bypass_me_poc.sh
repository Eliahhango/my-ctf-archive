#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: Bypass Me
# Category: Reverse Engineering
# Difficulty: Medium
# Event: picoCTF 2026
# Author: PRINCE NIYONSHUTI N.
#
# Description:
# We are given a password-protected binary called bypassme.bin. The prompt hints
# that the binary performs input sanitization and suggests thinking like an
# attacker using a debugger such as LLDB.
#
# Given information from the challenge:
# SSH host: foggy-cliff.picoctf.net
# SSH port: 62735
# SSH user: ctf-player
# SSH password: f3b61b38
# Target binary: bypassme.bin
#
# Files in this challenge directory:
# - bypassme.bin
# - this proof of concept script
#
# Core lesson:
# "Sanitization" printed to the screen is not the same thing as the value used
# for the actual security decision.
#
# Real-world analogy:
# Many applications log or display a cleaned-up version of user input, while the
# backend compares or processes a different internal value.
# If defenders only trust what they see in logs or the UI, they can miss how the
# program really behaves underneath.
#
# In this binary:
# - the program sanitizes the input only for DISPLAY
# - the password comparison uses the RAW input buffer
# - the true password is not typed anywhere in plain text
# - it is reconstructed at runtime with XOR
#
# This is a very common reverse-engineering pattern:
# 1. hide a value in obfuscated bytes
# 2. decode it at runtime
# 3. compare user input against the decoded result
#
# Step 1: Pull the binary locally for analysis.
# Manual command:
# scp -P 62735 ctf-player@foggy-cliff.picoctf.net:bypassme.bin .
#
# Why this matters:
# Local analysis is usually easier than guessing or debugging only through a
# remote terminal. We can inspect symbols, strings, and assembly much faster.
#
# Step 2: Check whether the binary is stripped.
# Manual command:
# file bypassme.bin
# nm -C bypassme.bin
#
# Why this matters:
# This binary is not stripped and includes helpful function names:
# - decode_password(char*)
# - sanitize(char const*, char*)
# - auth_sequence()
# - intro_sequence()
#
# In the real world, debug symbols often leak valuable implementation details.
# Even partial symbols can significantly reduce reverse-engineering time.
#
# Step 3: Inspect strings for clues.
# Manual command:
# strings -n 4 bypassme.bin
#
# Important clues we get:
# - "Raw Input: [%s]"
# - "Sanitized Input:[%s]"
# - "../../root/flag.txt"
#
# Why this matters:
# These strings tell us:
# - the program shows both raw and sanitized input
# - sanitization is probably a decoy or partial defense
# - successful authentication opens a flag file relative to the binary's path
#
# Step 4: Disassemble the key functions.
# Manual command:
# objdump -d -Mintel bypassme.bin | \
#   sed -n '/<_Z15decode_passwordPc>:/,/^$/p;/<_Z8sanitizePKcPc>:/,/^$/p;/<main>:/,/^$/p'
#
# What sanitize() does:
# It copies only alphabetic characters into a separate buffer.
#
# Why that matters:
# This makes the "Sanitized Input" look security-related, but main() later does:
# strcmp(raw_input, decoded_password)
# not:
# strcmp(sanitized_input, decoded_password)
#
# This is a classic misdirection pattern.
# The displayed transformation is not the actual enforcement path.
#
# Real-world lesson:
# Always trace the variable that reaches the security check.
# If authorization depends on variable A, it does not matter how heavily
# variable B was filtered, logged, or displayed.
#
# Step 5: Recover the hidden password from decode_password().
# Manual reverse-engineering observation:
# decode_password() stores obfuscated bytes and XORs each byte with 0xaa.
#
# The obfuscated bytes are:
# f9 df da cf d8 f9 cf c9 df d8 cf
#
# Undoing the XOR:
# byte ^ 0xaa
#
# Manual command:
# python3 - <<'PY'
# obf = [0xf9,0xdf,0xda,0xcf,0xd8,0xf9,0xcf,0xc9,0xdf,0xd8,0xcf]
# print(''.join(chr(x ^ 0xaa) for x in obf))
# PY
#
# Recovered password:
# SuperSecure
#
# Why this works:
# XOR obfuscation is reversible:
# if:
#   hidden = original ^ key
# then:
#   original = hidden ^ key
#
# Because XOR with the same key twice returns the original value.
#
# Real-world analogy:
# Attackers often find "hidden secrets" in binaries that are not really
# encrypted, only lightly transformed. XOR is useful for avoiding plain-text
# strings in a binary, but it is not secure storage for secrets.
#
# Step 6: Validate locally.
# Manual command:
# printf 'SuperSecure\n' | ./bypassme.bin
#
# Why this matters:
# Local validation proves our reverse-engineering result is correct before we
# spend time interacting with the remote system.
#
# You should see:
# - Raw Input: [SuperSecure]
# - Sanitized Input: [SuperSecure]
# - authentication progress
# - then "Flag file not found."
#
# The local run does not show the flag because the real flag file exists only on
# the challenge server.
#
# Step 7: Run the binary remotely with the recovered password.
# Manual command concept:
# ssh to the challenge host and pipe SuperSecure into ./bypassme.bin
#
# Why this matters:
# Once the binary runs in its real environment, fopen("../../root/flag.txt", "r")
# succeeds and prints the actual flag.
#
# Flag obtained:
# picoCTF{d3bugg3r_p0w3r_is_4w3s0m3_9df7c6a6}

host="foggy-cliff.picoctf.net"
port="62735"
user="ctf-player"
ssh_password="f3b61b38"
recovered_password="SuperSecure"

cat >/tmp/bypass_me_poc_askpass.sh <<EOF
#!/usr/bin/env bash
printf '%s' '$ssh_password'
EOF
chmod +x /tmp/bypass_me_poc_askpass.sh

ssh_output="$(
  DISPLAY=:0 \
  SSH_ASKPASS=/tmp/bypass_me_poc_askpass.sh \
  SSH_ASKPASS_REQUIRE=force \
  setsid -w ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/tmp/bypass_me_poc_known_hosts \
    -p "$port" \
    "$user@$host" \
    "printf '$recovered_password\n' | ./bypassme.bin" 2>&1
)"

printf '%s\n' "$ssh_output" | grep -o 'picoCTF{[^}]*}'
