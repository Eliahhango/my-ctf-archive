# An unusual sighting

## Overview

This directory contains the local materials and saved solve workflow for the `An unusual sighting` challenge on Hack The Box. This is a forensics challenge based on SSH logs and shell history from a compromised development server. The solve is not about breaking a service directly. It is about reading the timeline carefully and extracting the exact indicators the remote quiz expects.

The saved PoC answers the live question flow automatically. This README explains how those answers are derived and what to look for if you want to solve it manually.

## Challenge Profile

- Challenge: `An unusual sighting`
- Category: `Forensics`
- Platform: `Hack The Box`
- Saved PoC: `an_unusual_sighting_poc.sh`

## Directory Contents

- `an_unusual_sighting_poc.sh`
- `challenge.zip`
- `forensics_an_unusual_sighting.zip`

## First Commands To Run

Start by listing the folder and checking the archives:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/An_unusual_sighting"
ls -lah
unzip -l "challenge.zip"
unzip -l "forensics_an_unusual_sighting.zip"
```

Read the saved PoC:

```bash
sed -n "1,220p" "an_unusual_sighting_poc.sh"
```

Run it:

```bash
chmod +x "an_unusual_sighting_poc.sh"
./an_unusual_sighting_poc.sh
```

To reuse it against a fresh spawned target:

```bash
./an_unusual_sighting_poc.sh <HOST> <PORT>
```

## What The Challenge Asks For

The service expects a fixed sequence of answers derived from two forensic artifacts:

- SSH logs
- Bash history

The important job is to identify:

- the source IP and port used by the attacker
- the first successful login
- the suspicious login time
- the attacker public key fingerprint
- the first command after login
- the final command before logout

This is a classic timeline-building exercise.

## Manual Analysis Approach

If you want to solve it manually after extracting the archive, the first useful commands are usually:

```bash
unzip forensics_an_unusual_sighting.zip -d extracted
find extracted -type f | sort
```

Then inspect the log and history files with:

```bash
less extracted/*
rg -n "Accepted|Failed|publickey|session|whoami|setup" extracted
```

For SSH-related forensic review, look for lines that show:

- accepted authentication events
- source IP and source port
- authentication method
- session open and close times
- associated key material or fingerprints

For shell history, look for:

- the first command after the suspicious login
- the final command before the shell session ends

## Recovered Answers

The values recovered during solving were:

- SSH server: `100.107.36.130:2221`
- First successful login: `2024-02-13 11:29:50`
- Unusual login time: `2024-02-19 04:00:14`
- Attacker public key fingerprint: `OPkBSs6okUKraq8pYo4XwwBg55QSo210F09FCe1-yj4`
- First command after login: `whoami`
- Final command before logout: `./setup`

The saved PoC simply waits for each prompt from the service and submits those answers in order.

## Why This Challenge Is Useful

This is a good introductory forensics exercise because it trains the habit of extracting exact values from system artifacts instead of relying on vague impressions. In incident response, small details matter:

- a single timestamp can identify the actual intrusion window
- a source port can help tie events together
- a public key fingerprint can attribute access across multiple systems
- command history can reveal attacker intent immediately

## Reproduction Commands

Use this sequence for the shortest path:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/An_unusual_sighting"
unzip -l "forensics_an_unusual_sighting.zip"
sed -n "1,220p" "an_unusual_sighting_poc.sh"
bash "an_unusual_sighting_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are practicing basic incident-response workflows. The PoC provides the final answers quickly, but the more valuable exercise is to extract each answer manually from the logs and build the attacker timeline yourself before comparing it to the script.
