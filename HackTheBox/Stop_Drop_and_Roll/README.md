# Stop Drop and Roll

## Overview

This directory contains the local materials and manual walkthrough for the `Stop Drop and Roll` challenge on Hack The Box. This is a lightweight scripting challenge built around a repeated text-based protocol. The puzzle itself is simple. The real point is to recognize that any repetitive rule-based interaction becomes trivial once you script the mapping cleanly.

The archived notes in this folder show one way to automate the repeated prompt handling, but the manual protocol is fully explained below.

## Challenge Profile

- Challenge: `Stop Drop and Roll`
- Category: `Misc / Scripting`
- Platform: `Hack The Box`

## Directory Contents

- `stop_drop_and_roll_poc.sh`

## First Commands To Run

This folder does not include original challenge files. Follow the walkthrough the same way you would read a public writeup: understand the target behavior first, then reproduce each manual step against a fresh instance until the flag is visible.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Stop_Drop_and_Roll"
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

## Service Behavior

The remote service presents one or more hazards chosen from a fixed vocabulary:

- `GORGE` maps to `STOP`
- `PHREAK` maps to `DROP`
- `FIRE` maps to `ROLL`

If multiple hazards appear on one line, the answer must preserve the same order and join the mapped actions with hyphens.

Example:

```text
GORGE, FIRE, PHREAK
```

becomes:

```text
STOP-ROLL-DROP
```

## Why This Challenge Is Scriptable

There is no hidden state, no cryptography, and no exploitation in the usual sense. Each round is just a deterministic transformation of one line of text into another. Once you identify the mapping, the rest of the challenge is:

1. keep the TCP connection open
2. wait for the prompt
3. parse the hazard line
4. map each token
5. send the joined response

The only reason this is annoying for a human is volume. The service expects many correct answers in sequence, so automation is the natural solution.

## Manual Test Idea

If you want to observe the protocol manually once before using the script, connect with `nc` and answer a few rounds by hand:

```bash
nc <HOST> <PORT>
```

Once you see the repeated structure, the need for scripting becomes obvious.

## Optional Archive Reference

The same interaction can be done manually:

- connects to the TCP service
- sends `y` to start
- waits for the `What do you do?` prompt
- extracts the line immediately above it
- maps each hazard to the proper action
- responds quickly enough to complete all rounds

This is a useful pattern for many CTF “interactive trivia” services where a short parser is all that is required.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Stop_Drop_and_Roll"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `HTB{1_wiLl_sT0p_dR0p_4nD_r0Ll_mY_w4Y_oUt!}`

## Study Notes

This challenge is worth revisiting if you are practicing socket scripting and prompt parsing. It is a good reminder that a task does not need to be technically deep to reward automation. If a rule is deterministic and repeated enough times, the cleanest solution is almost always a script.
