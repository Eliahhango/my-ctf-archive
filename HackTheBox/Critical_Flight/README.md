# Critical Flight

## Overview

This directory contains the local materials and saved solve workflow for the `Critical Flight` challenge on Hack The Box CTF Try Out. This is a hardware-focused challenge based on Gerber PCB production files. The goal is to inspect the board layers individually and notice that the flag is hidden across multiple copper layers rather than in the obvious top-level board view.

This challenge is useful because it teaches a real hardware review habit: never trust only the rendered top or fully composited board image. Critical information can be buried inside inner or bottom layers.

## Challenge Profile

- Challenge: `Critical Flight`
- Category: `Hardware`
- Platform: `Hack The Box CTF Try Out`
- Saved PoC: `critical_flight_poc.sh`

## Directory Contents

- `critical_flight_poc.sh`
- `flight_control_board/`
- `hw_critical_flight.zip`
- `layers/`
- `rendered_bottom.png`
- `rendered_bottom.svg`
- `rendered_top.png`
- `rendered_top.svg`
- `rendered_top_big.png`
- `rendered_top_big_inv.png`

## First Commands To Run

Start by reviewing the folder and the archive:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Critical_Flight"
ls -lah
unzip -l "hw_critical_flight.zip"
```

Read the saved PoC:

```bash
sed -n "1,220p" "critical_flight_poc.sh"
```

Run it:

```bash
chmod +x "critical_flight_poc.sh"
./critical_flight_poc.sh
```

## What Gerber Files Are

Gerber files are manufacturing files used to fabricate printed circuit boards. A board is not stored as a single flat image. It is split into layers such as:

- top copper
- bottom copper
- internal copper layers
- silkscreen
- solder mask
- edge cuts

That layer structure is exactly what makes this challenge interesting.

## Core Idea Of The Challenge

The hidden content is not visible if you only inspect the board casually. The flag has been split across different copper layers, so the solve requires isolating layers one by one and reading the text fragments from the correct views.

The relevant files recovered during solving were:

- `flight_control_board/HadesMicro-B_Cu.gbr`
- `flight_control_board/HadesMicro-In1_Cu.gbr`

Those two layers contain the two halves of the flag.

## Manual Solve Workflow

If you want to retrace the solve in a Gerber viewer:

1. Open the full Gerber set.
2. Hide every layer.
3. Show only the bottom copper layer.
4. Read the visible fragment on `B_Cu`.
5. Hide it and show the internal copper layer `In1_Cu`.
6. Read the second visible fragment.
7. Join the two strings.

The recovered fragments were:

- from `B_Cu`:

```text
HTB{533_7h3_1nn32_w02k1n95
```

- from `In1_Cu`:

```text
_0f_313c720n1c5#$@}
```

Combined, they yield the final flag.

## Why This Matters In Real Hardware Work

In real PCB reviews, malicious or suspicious content can be hidden in ways that are invisible from the top silkscreen or from a simplified rendering:

- hidden traces
- covert antennas
- debug backdoors
- inner-layer text or identifiers
- copper art that encodes data

This challenge is a compact demonstration of why layer-by-layer inspection matters.

## Useful Local Files

This folder already includes rendered images and extracted layers, which makes it easier to study the result without reopening the archive from scratch. You can inspect those assets directly if you want a quicker visual review.

```bash
find flight_control_board -type f | sort
find layers -type f | sort
```

## Reproduction Commands

Use this sequence for the shortest fast path:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Critical_Flight"
unzip -l "hw_critical_flight.zip"
sed -n "1,220p" "critical_flight_poc.sh"
bash "critical_flight_poc.sh"
```

## Study Notes

This is a good challenge to revisit if you want practical exposure to PCB artifact review. The solve is simple once you know where to look, but the habit it teaches is valuable: isolate layers, verify assumptions, and do not let a polished top-level rendering hide what is actually present in the design files.
