#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: Follow The Media
# Category: OSINT
# Difficulty: Medium
# Event: CTFZone
#
# Description:
# We are given a markdown description and told to investigate a user named
# James Adam with:
# - alias: lazyatom
# - joined: 2018
#
# Flag format:
# ctfzone{id_acct_elsewhere_githubUsername_NumberOfFollowers}
#
# Core lesson:
# Public identity data often becomes much more useful when you combine profiles
# across multiple platforms. One account rarely gives everything away, but a
# chain of small public clues can reveal exactly what you need.
#
# High-level OSINT path used here:
# 1. Start from the seed alias "lazyatom".
# 2. Query the lazyatom.social Mastodon account for James Adam.
# 3. Notice the linked "Also" profile pointing to ruby.social/@james.
# 4. Query the ruby.social profile as a federated account from lazyatom.social.
# 5. Extract:
#    - id
#    - acct
#    - Elsewhere field
#    - Github field
#    - followers_count
# 6. Format those into the challenge flag.
#
# Why the federated lookup matters:
# The starting lazyatom.social profile gives us the first breadcrumb and points
# to ruby.social/@james. But if we query that account from lazyatom.social as a
# remote federated profile, Mastodon returns:
# - the remote account id on that platform
# - the full acct value: james@ruby.social
# - the current follower count as seen from that platform
#
# That matches the wording better than using ruby.social's local short acct
# value "james".
#
# Manual commands used during solving:
#
# Step 1: Read the local description.
# sed -n '1,240p' description.md
#
# Step 2: Query the starting Mastodon account.
# curl -s 'https://lazyatom.social/api/v1/accounts/lookup?acct=james'
#
# Important clue found there:
# - id: 1
# - acct: james
# - followers_count: 196
# - Github: github.com/lazyatom
# - Also: https://ruby.social/@james
#
# Step 3: Follow the "Also" clue as a remote lookup on the original instance.
# curl -s 'https://lazyatom.social/api/v1/accounts/lookup?acct=james@ruby.social'
#
# Important data found there:
# - id: 118
# - acct: james@ruby.social
# - Elsewhere: lazyatom.com
# - Github: github.com/lazyatom
# - followers_count: 3530
#
# Step 4: Build the final flag.
# ctfzone{118_james@ruby.social_lazyatom.com_lazyatom_3530}
#
# Real-world concept:
# This is a classic OSINT identity pivot:
# - one profile gives a cross-link
# - the second profile gives the exact metadata label you need
# - a personal site confirms the same identity chain
#
# Flag obtained:
# ctfzone{118_james@ruby.social_lazyatom.com_lazyatom_3530}

python3 - <<'PY'
import json
import re
import urllib.request
from urllib.parse import urlparse


def fetch_json(url: str):
    with urllib.request.urlopen(url, timeout=20) as resp:
        return json.load(resp)


def extract_href(html_fragment: str) -> str:
    match = re.search(r'href="([^"]+)"', html_fragment)
    if match:
        return match.group(1).strip()
    return html_fragment.strip()


start_profile = fetch_json("https://lazyatom.social/api/v1/accounts/lookup?acct=james")
ruby_profile = fetch_json("https://lazyatom.social/api/v1/accounts/lookup?acct=james@ruby.social")

# We finalize on the federated ruby.social account as seen from lazyatom.social
# because that yields the platform-specific remote id and the full acct value.
profile_id = ruby_profile["id"]
acct = ruby_profile["acct"]
followers = ruby_profile["followers_count"]

fields = {field["name"].lower(): extract_href(field["value"]) for field in ruby_profile["fields"]}
elsewhere = urlparse(fields["elsewhere"]).netloc or fields["elsewhere"]
github_username = urlparse(fields["github"]).path.rstrip("/").split("/")[-1]

flag = f"ctfzone{{{profile_id}_{acct}_{elsewhere}_{github_username}_{followers}}}"
print(flag)
PY
