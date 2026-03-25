# Character

## Overview

This directory contains the local materials and manual walkthrough for the `Character` challenge on Hack The Box. This is a very simple terminal-style challenge, but it demonstrates an important security lesson clearly: leaking a secret one character at a time is still leaking the secret.

The service is designed to feel tedious for a human. The correct response is to automate the repeated requests and reconstruct the full flag from the individual character disclosures.

## Challenge Profile

- Challenge: `Character`
- Category: `terminal / warmup`
- Platform: `Hack The Box`
- Difficulty: `very easy`

## Directory Contents

- `character_poc.sh`

## First Commands To Run

This folder does not include original challenge files. Start by reading the challenge description and the manual walkthrough below, then connect to a fresh challenge instance and reproduce the steps one by one.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Character"
ls -lah
printf 'Follow the manual walkthrough below against the live service.\n'
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

## Optional Archive Reference

The archived notes in this folder automate the same idea by keeping one socket open, sending increasing integers, and parsing lines of the form:

```text
Character at Index N: X
```

and appends each returned character to a local string until the service reports that the index is out of range.

The script also handles slight network timing issues by performing short follow-up reads when the result and the next prompt arrive in separate packets.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Character"
ls -lah
```

## Study Notes

This challenge is easy, but it teaches a real principle: if a service lets an attacker query secret state incrementally, the attacker can usually automate the collection process. It is a useful warmup for basic socket scripting and response parsing.
