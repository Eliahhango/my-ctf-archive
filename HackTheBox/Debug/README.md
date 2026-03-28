# Debug

## Overview

This directory contains the local materials and manual walkthrough for the `Debug` challenge on Hack The Box CTF Try Out. This is a hardware forensics challenge based on a Saleae logic capture. The solve is not about exploitation in the usual sense. It is about identifying the electrical interface correctly, decoding the traffic with the proper serial settings, and recognizing that the boot log itself leaks the flag.

The archived notes in this folder preserve the recovered flag, but the real learning value comes from recognizing UART in the raw capture and recovering the correct baud rate.

## Challenge Profile

- Challenge: `Debug`
- Category: `Hardware`
- Platform: `Hack The Box CTF Try Out`

## Directory Contents

- `debug_poc.sh`
- `hw_debug.sal`
- `hw_debug.zip`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Debug"
ls -lah
unzip -l "hw_debug.zip"
```

Useful first inspection commands:

```bash
file 'hw_debug.zip'
strings -n 5 'hw_debug.zip' | head -200
```

Open `hw_debug.sal` in Logic 2 / Saleae and add the appropriate analyzer as described in the walkthrough below.

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## What The File Represents

The provided `.sal` file is a Saleae Logic capture. That means it stores recorded digital signals from a logic analyzer session. In practical hardware work, files like this are used to inspect buses and interfaces such as:

- UART
- SPI
- I2C
- GPIO transitions

The challenge description points toward a debug interface and serial boot communication, which strongly suggests UART rather than a packetized bus like SPI or I2C.

## Why UART Is The Correct Interpretation

Inside the capture, the important channels are labeled:

- `TX`
- `RX`

Those names are the strongest immediate clue. They are the standard labels for asynchronous serial transmit and receive lines. That makes `Async Serial` or `UART` the right decoder to try first in Logic 2.

## How To Decode The Capture

If you want to solve it manually in Logic 2:

1. Open `hw_debug.sal`.
2. Focus on the `RX` line.
3. Add an `Async Serial` analyzer.
4. Measure the width of one bit period.
5. Convert that width into a baud rate.

The measured bit width is approximately:

```text
8.68 microseconds
```

That corresponds to:

```text
1 / 0.00000868 ≈ 115200 baud
```

So the correct decoder settings are:

- baud rate: `115200`
- data bits: `8`
- parity: `none`
- stop bits: `1`

Once those settings are applied, the boot output becomes readable.

## What The Decoded Output Reveals

Near the end of the decoded serial stream, the boot log leaks the flag in fragments:

```text
WARNING: The deep space observatory is offline HTB{
INFO: Communication systems are offline reference code: 547311173_
WARNING: Unauthorized subroutines detected! reference code: n37w02k_
WARNING: The satellite dish can not sync with the swarm. reference code: c0mp20m153d}
```

Putting those lines together yields:

```text
HTB{547311173_n37w02k_c0mp20m153d}
```

## Why This Challenge Is Useful

This challenge teaches a very realistic embedded-systems lesson: debug output often leaks far more than developers intend. Even if the device is not directly exploitable at the firmware level, serial logs can expose:

- identifiers
- internal state
- credentials
- reference values
- secret material

Any exposed debug UART on real hardware should be treated as sensitive.

## Manual Workflow

Use this workflow if you want to retrace the solve manually:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Debug"
unzip -l "hw_debug.zip"
```

Then open `hw_debug.sal` in Logic 2 and:

- add an `Async Serial` decoder on `RX`
- set baud to `115200`
- inspect the decoded text near the end of the capture

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Debug"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `HTB{547311173_n37w02k_c0mp20m153d}`

## Study Notes

This challenge is worth revisiting if you are practicing hardware-oriented incident analysis. It is a good example of how physical interfaces and “harmless” debug output can become a direct source of sensitive information.
