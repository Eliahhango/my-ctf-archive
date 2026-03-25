# ping-cmd

## Overview

This directory contains the local materials and manual walkthrough for the `ping-cmd` challenge from `picoCTF 2026`. The goal of this README is to make the folder immediately useful to someone reviewing the archive later: what the challenge was about, what files matter, how the solve works at a high level, and which commands to run first.

## Challenge Profile

- Challenge: `ping-cmd`
- Category: `General Skills`
- Collection: `picoCTF`
- Event or Platform: `picoCTF 2026`
- Difficulty: `Medium`
- Author: `YAHAYA MEDDY`

## Directory Contents

- `ping_cmd_poc.sh`

## First Commands To Run

This folder does not include original challenge files. Start by reading the challenge description and the manual walkthrough below, then connect to a fresh challenge instance and reproduce the steps one by one.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/ping-cmd"
ls -lah
printf 'Follow the manual walkthrough below against the live service.\n'
```

## Walkthrough

Challenge Name: ping-cmd
Category: General Skills
Difficulty: Medium
Event: picoCTF 2026
Author: YAHAYA MEDDY

### Description

"Can you make the server reveal its secrets? It seems to be able to ping
Google DNS, but what happens if you get a little creative with your input?"

### Given information from the challenge

Remote service: nc mysterious-sea.picoctf.net 64997
Prompt message:
"Enter an IP address to ping! (We have tight security because we only allow
'8.8.8.8')"

### Core lesson

This challenge is about command injection.
The application pretends to only accept one safe IP address, but it still
passes user input into a shell command in an unsafe way.

### Real-world analogy

Imagine a web admin panel that runs:
ping <user_input>
on the server after "validating" the input with a weak string check.

If the developer only checks whether the input starts with something safe,
but still lets shell metacharacters through, an attacker can append a second
command such as:
; cat /etc/passwd

The first command looks legitimate, but the shell sees the semicolon and runs
both commands.

### High-level attack plan

1. Send the allowed value 8.8.8.8 to observe normal behavior.
2. Test whether shell separators like ;, &&, or | are interpreted.
3. Confirm command injection by running id.
4. Read flag.txt using the same injection primitive.

### Step 1: Check the normal behavior.

Manual command:
printf '8.8.8.8\n' | nc mysterious-sea.picoctf.net 64997

Reason:
This shows the service really runs ping and returns the output. Establishing a
baseline first is useful because it tells us what "normal" looks like before
we start testing abuse cases.

### Step 2: Test whether the input is passed to a shell.

Manual command:
printf '8.8.8.8;id\n' | nc mysterious-sea.picoctf.net 64997

Reason:
The semicolon is a shell command separator.
If the backend runs something like:
system("ping -c 2 " + user_input)
then:
8.8.8.8;id
becomes:
ping -c 2 8.8.8.8; id

and the server runs both commands.

In the solved instance, the output includes:
uid=1000(ctf-player) gid=1000(ctf-player) groups=1000(ctf-player)

That proves we have command injection.

### Step 3: Use the same primitive to read the flag.

Manual command:
printf '8.8.8.8;cat flag.txt\n' | nc mysterious-sea.picoctf.net 64997

Reason:
Once we know arbitrary shell commands are executing, the shortest path to the
flag is to read the file directly. The original ping command still runs, but
the shell then executes:
cat flag.txt

and prints the flag in the same response.

Real-world security concept:
Command injection is dangerous because it turns a simple feature such as
"diagnose network connectivity" into remote code execution. The safe fix is:
- avoid shell=True / system() when possible
- pass arguments directly to an API like execve/subprocess.run([...])
- strictly validate input as data, not shell syntax

### Flag obtained

picoCTF{p1nG_c0mm@nd_3xpL0it_su33essFuL_252214ae}

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/ping-cmd"
ls -lah
```

## Study Notes

This folder is best used as a practical study reference for `General Skills`-style problems. Work through the manual inspection and exploitation steps first, then compare your reasoning against the archived solve notes if you want an extra cross-check.
