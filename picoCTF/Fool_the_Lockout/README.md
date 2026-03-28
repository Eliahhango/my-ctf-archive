# Fool the Lockout

## Overview

This directory contains the local materials and manual walkthrough for the `Fool the Lockout` challenge from `picoCTF 2026`. This is a web challenge centered on a login rate limiter that looks effective at first glance but is weak in practice. The defense only blocks fast brute force. A patient attacker can stay within the threshold, wait for the reset window, and continue credential stuffing safely.

The challenge is a useful example of how security controls can fail at the policy level even when they appear to work at the UI level.

## Challenge Profile

- Challenge: `Fool the Lockout`
- Category: `Web Exploitation`
- Collection: `picoCTF`
- Event or Platform: `picoCTF 2026`
- Difficulty: `Medium`
- Author: `DAVID GAVIRIA`

## Directory Contents

- `app.py`
- `creds-dump.txt`
- `fool_the_lockout_poc.sh`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Fool_the_Lockout"
ls -lah
```

Useful first inspection commands:

```bash
sed -n '1,220p' 'app.py'
sed -n '1,220p' 'creds-dump.txt'
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Core Weakness

The application rate-limits by source IP and counts only POST attempts within a fixed epoch. The key problem is that the design does not actually stop credential stuffing. It only slows down requests that exceed the threshold too quickly.

The correct attacker strategy is therefore not to avoid the rate limiter entirely, but to cooperate with its reset logic:

- send up to the allowed number of attempts
- wait slightly longer than the epoch
- resume testing the next batch of credentials

That bypasses the intended lockout without any exotic technique.

## What Matters In The Source Code

When you read `app.py`, focus on:

- the rate-limit bucket key
- the epoch duration
- the maximum requests per epoch
- when lockout is triggered
- whether the limit is per-IP, per-user, or truly global

The challenge makes the mistake of using a very simple timing-based policy. That creates a wide gap between “too fast” and “completely impossible.”

## Why The Credential Dump Changes The Problem

The application does not require you to search the entire universe of username and password combinations. The credential dump already constrains the search space to a realistic list of candidate pairs.

That means the attack is not:

- generic password guessing

It is:

- careful credential stuffing against a known candidate list

Once you have a finite set of inputs and a weak timing-based rate limit, automation becomes straightforward.

## Practical Attack Strategy

The safe approach is:

1. load the candidate credentials from the dump
2. submit up to the allowed number of login attempts
3. sleep until the epoch resets
4. continue with the next batch
5. stop when the login redirect indicates success

The folder also preserves both of these helper approaches as reference:

- a fast mode using the already recovered valid credential
- a slower `--bruteforce` mode that reproduces the patient attack strategy

That makes the folder useful both as a quick solve and as a demonstration of the actual bypass logic.

## Why This Challenge Matters

This is a very realistic web-security lesson. Many systems defend only against loud, rapid attacks and fail against low-and-slow behavior. If the lockout policy is entirely time-window based, an attacker can often adapt to it with simple automation.

Real defenses need more than a single threshold. They usually require some combination of:

- account-based tracking
- behavioral analysis
- anomaly detection
- MFA
- credential stuffing detection
- stronger authentication design overall

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Fool_the_Lockout"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `picoCTF{f00l_7h4t_l1m1t3r_b9fcf635}`

## Study Notes

This folder is worth revisiting if you are studying login abuse, rate-limit design, and low-noise automation. It is a good reminder that a control can be functioning exactly as written and still fail as a defense.
