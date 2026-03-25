# Debug

## Overview

This directory contains the local materials and saved solve workflow for the `Debug` challenge on Hack The Box CTF Try Out. This is a hardware forensics challenge based on a Saleae logic capture. The solve is not about exploitation in the usual sense. It is about identifying the electrical interface correctly, decoding the traffic with the proper serial settings, and recognizing that the boot log itself leaks the flag.

The saved PoC prints the final flag immediately, but the real learning value comes from understanding how to recognize UART in a raw capture and how to recover the correct baud rate.

## Challenge Profile

- Challenge: `Debug`
- Category: `Hardware`
- Platform: `Hack The Box CTF Try Out`
- Saved PoC: `debug_poc.sh`

## Directory Contents

- `debug_poc.sh`
- `hw_debug.sal`
- `hw_debug.zip`

## First Commands To Run

Start by reviewing the local files and the original archive:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Debug"
ls -lah
unzip -l "hw_debug.zip"
```

Read the saved PoC:

```bash
sed -n "1,220p" "debug_poc.sh"
```

Run it:

```bash
chmod +x "debug_poc.sh"
./debug_poc.sh
```

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
sed -n "1,220p" "debug_poc.sh"
```

Then open `hw_debug.sal` in Logic 2 and:

- add an `Async Serial` decoder on `RX`
- set baud to `115200`
- inspect the decoded text near the end of the capture

## Reproduction Commands

Use this sequence for the fast path:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Debug"
unzip -l "hw_debug.zip"
sed -n "1,220p" "debug_poc.sh"
bash "debug_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are practicing hardware-oriented incident analysis. It is a good example of how physical interfaces and “harmless” debug output can become a direct source of sensitive information.
