# Character

## Overview

This directory contains the local materials and saved solve workflow for the `Character` challenge on Hack The Box. This is a very simple terminal-style challenge, but it demonstrates an important security lesson clearly: leaking a secret one character at a time is still leaking the secret.

The service is designed to feel tedious for a human. The correct response is to automate the repeated requests and reconstruct the full flag from the individual character disclosures.

## Challenge Profile

- Challenge: `Character`
- Category: `terminal / warmup`
- Platform: `Hack The Box`
- Difficulty: `very easy`
- Saved PoC: `character_poc.sh`

## Directory Contents

- `character_poc.sh`

## First Commands To Run

Read the saved PoC:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Character"
ls -lah
sed -n "1,220p" "character_poc.sh"
```

Run it:

```bash
chmod +x "character_poc.sh"
./character_poc.sh
```

To point it at a new spawned instance:

```bash
./character_poc.sh <HOST> <PORT>
```

## What The Service Does

The challenge exposes a service that accepts an integer index and returns the corresponding flag character. It keeps doing this until the requested index is outside the valid range.

So the interaction model is effectively:

1. send index
2. receive one character
3. increment index
4. repeat until the service says the index is out of range

## Why This Is A Security Problem

Sometimes developers believe they are safe because they do not reveal the whole secret at once. That is not real protection. If an attacker can query one position at a time, they can reconstruct the entire value with trivial automation.

This challenge is a good reminder that partial disclosure remains disclosure.

## Manual Solve Idea

If you want to see the issue manually once, connect with `nc`:

```bash
nc <HOST> <PORT>
```

Then request:

- `0`
- `1`
- `2`
- `3`

You will quickly see that the service is just walking you through the flag one position at a time.

That is the point where scripting becomes the obvious answer.

## What The Saved PoC Does

The PoC keeps one socket open, sends increasing integers, parses lines of the form:

```text
Character at Index N: X
```

and appends each returned character to a local string until the service reports that the index is out of range.

The script also handles slight network timing issues by performing short follow-up reads when the result and the next prompt arrive in separate packets.

## Reproduction Commands

Use this sequence for the fast path:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Character"
sed -n "1,220p" "character_poc.sh"
bash "character_poc.sh"
```

## Study Notes

This challenge is easy, but it teaches a real principle: if a service lets an attacker query secret state incrementally, the attacker can usually automate the collection process. It is a useful warmup for basic socket scripting and response parsing.
