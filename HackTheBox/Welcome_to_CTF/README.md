# Welcome to CTF

## Overview

This directory contains the local materials and manual walkthrough for the `Welcome to CTF` challenge on Hack The Box. This is the onboarding warmup challenge, and its purpose is to reinforce the most basic habit in CTF work: inspect what the service already gives you before looking for something more complicated.

There is no exploit here. The flag is exposed directly in the HTTP response.

## Challenge Profile

- Challenge: `Welcome to CTF`
- Category: `Warmup`
- Platform: `Hack The Box`

## Directory Contents

- `welcome_to_ctf_poc.sh`

## First Commands To Run

This folder does not include original challenge files. Follow the walkthrough the same way you would read a public writeup: understand the target behavior first, then reproduce each manual step against a fresh instance until the flag is visible.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Welcome_to_CTF"
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

## What The Challenge Teaches

This warmup exists to show that not every target starts with exploitation. Sometimes the correct first move is simply:

1. identify the service
2. fetch the response
3. inspect the output carefully

That is exactly what happens here.

## Manual Solve Workflow

If you want to retrace the solve manually, start by identifying the service:

```bash
nmap -sV -Pn -p <PORT> <HOST>
```

That reveals a small HTTP service. The next step is to request the homepage:

```bash
curl -s "http://<HOST>:<PORT>/"
```

The returned HTML already contains the first flag. To extract it cleanly:

```bash
curl -s "http://<HOST>:<PORT>/" | grep -o 'HTB{[^}]*}'
```

## Why This Is A Good Warmup

The lesson is simple but important: sensitive values are sometimes exposed directly in client-facing responses. Before spending time on scanning, fuzzing, or exploitation, it is worth checking the page source, headers, JavaScript, and basic endpoints carefully.

Many easy challenge solves and many real web findings come from observation rather than technical exploitation.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Welcome_to_CTF"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `HTB{onboard1ng_fl4g}`

## Study Notes

This challenge is intentionally basic, but it is worth keeping in the archive because it reinforces the right early workflow: identify the service, inspect the response, and confirm whether the application is already exposing useful data before doing anything more advanced.
