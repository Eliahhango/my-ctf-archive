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

This folder does not include original challenge files. Start by reading the challenge description and the manual walkthrough below, then connect to a fresh challenge instance and reproduce the steps one by one.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Welcome_to_CTF"
ls -lah
printf 'Follow the manual walkthrough below against the live service.\n'
```

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

## Study Notes

This challenge is intentionally basic, but it is worth keeping in the archive because it reinforces the right early workflow: identify the service, inspect the response, and confirm whether the application is already exposing useful data before doing anything more advanced.
