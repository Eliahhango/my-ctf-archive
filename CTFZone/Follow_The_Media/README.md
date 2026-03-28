# Follow The Media

## Overview

This directory contains the local materials and manual walkthrough for the `Follow The Media` challenge from `CTFZone`. The goal of this README is to make the folder immediately useful to someone reviewing the archive later: what the challenge was about, what files matter, how the solve works at a high level, and which commands to run first.

## Challenge Profile

- Challenge: `Follow The Media`
- Category: `OSINT`
- Collection: `CTFZone`
- Event or Platform: `CTFZone`
- Difficulty: `Medium`

## Directory Contents

- `description.md`
- `follow_the_media_poc.sh`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/CTFZone/Follow_The_Media"
ls -lah
```

Useful first inspection commands:

```bash
sed -n '1,220p' 'description.md'
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Walkthrough

Challenge Name: Follow The Media
Category: OSINT
Difficulty: Medium
Event: CTFZone

### Description

We are given a markdown description and told to investigate a user named
James Adam with:
- alias: lazyatom
- joined: 2018

Flag format:
ctfzone{id_acct_elsewhere_githubUsername_NumberOfFollowers}

### Core lesson

Public identity data often becomes much more useful when you combine profiles
across multiple platforms. One account rarely gives everything away, but a
chain of small public clues can reveal exactly what you need.

### High-level OSINT path used here

1. Start from the seed alias "lazyatom".
2. Query the lazyatom.social Mastodon account for James Adam.
3. Notice the linked "Also" profile pointing to ruby.social/@james.
4. Query the ruby.social profile as a federated account from lazyatom.social.
5. Extract:
- id
- acct
- Elsewhere field
- Github field
- followers_count
6. Format those into the challenge flag.

### Why the federated lookup matters

The starting lazyatom.social profile gives us the first breadcrumb and points
to ruby.social/@james. But if we query that account from lazyatom.social as a
remote federated profile, Mastodon returns:
- the remote account id on that platform
- the full acct value: james@ruby.social
- the current follower count as seen from that platform

That matches the wording better than using ruby.social's local short acct
value "james".

### Manual commands used during solving

### Step 1: Read the local description.

sed -n '1,240p' description.md

### Step 2: Query the starting Mastodon account.

curl -s 'https://lazyatom.social/api/v1/accounts/lookup?acct=james'

Important clue found there:
- id: 1
- acct: james
- followers_count: 196
- Github: github.com/lazyatom
- Also: https://ruby.social/@james

### Step 3: Follow the "Also" clue as a remote lookup on the original instance.

curl -s 'https://lazyatom.social/api/v1/accounts/lookup?acct=james@ruby.social'

Important data found there:
- id: 118
- acct: james@ruby.social
- Elsewhere: lazyatom.com
- Github: github.com/lazyatom
- followers_count: 3530

### Step 4: Build the final flag.

ctfzone{118_james@ruby.social_lazyatom.com_lazyatom_3530}

### Real-world concept

This is a classic OSINT identity pivot:
- one profile gives a cross-link
- the second profile gives the exact metadata label you need
- a personal site confirms the same identity chain

### Flag obtained

ctfzone{118_james@ruby.social_lazyatom.com_lazyatom_3530}

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/CTFZone/Follow_The_Media"
ls -lah
```

## Final Flags

Following the manual path in this README leads to these recovered flags:

- `ctfzone{id_acct_elsewhere_githubUsername_NumberOfFollowers}`
- `ctfzone{118_james@ruby.social_lazyatom.com_lazyatom_3530}`

## Study Notes

This folder is best used as a practical study reference for `OSINT`-style problems. Follow the public-source trail manually first, then use the archived solve notes only to confirm the final chain of evidence.
