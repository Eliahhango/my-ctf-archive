# Shush Protocol

## Overview

This directory contains the local materials and manual walkthrough for the `Shush Protocol` challenge on Hack The Box CTF Try Out. This is an ICS/traffic-analysis challenge based on a Modbus/TCP packet capture. The critical lesson is that “custom” industrial protocol extensions do not become secure just because they are unusual. If the traffic is plaintext, secrets will still leak.

The solve comes from recognizing the protocol, following the right stream, and noticing that the password and flag appear directly in the traffic associated with a nonstandard function code.

## Challenge Profile

- Challenge: `Shush Protocol`
- Category: `ICS`
- Platform: `Hack The Box CTF Try Out`

## Directory Contents

- `ics_shush_protocol/`
- `ics_shush_protocol.zip`
- `shush_protocol_poc.sh`

## First Commands To Run

Start with the original challenge materials in this folder. The goal is to identify the bug or recovery path from the provided files, then follow the numbered walkthrough below to reach the flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Shush_Protocol"
ls -lah
unzip -l "ics_shush_protocol.zip"
```

Useful first inspection commands:

```bash
file 'ics_shush_protocol.zip'
strings -n 5 'ics_shush_protocol.zip' | head -200
```

## Protocol Identification

The provided traffic is Modbus/TCP. That is the first important observation. Once you filter on Modbus traffic, you can see familiar normal operations such as:

- function code `1` for read coils
- function code `3` for read holding registers

But there is also a repeated nonstandard function code:

- function code `102`

That is the signal that something application-specific is happening.

## Why Function Code 102 Matters

Standard Modbus does not use function `102` in this way. When you see a custom function code inside industrial traffic, that is often where authentication, management, or proprietary control logic has been added.

In this challenge, the unusual function code carries exactly the sensitive logic we care about.

## Manual Analysis Workflow

If you want to retrace the solve manually in Wireshark:

1. Open the capture.
2. Apply the display filter:

```text
modbus
```

3. Look for traffic that uses function code `102`.
4. Follow the TCP stream for that exchange.

A fast command-line alternative is:

```bash
tshark -r traffic.pcapng -z follow,tcp,ascii,1
```

Once you inspect the relevant stream, the important values are visible in plaintext.

## Recovered Values

The capture reveals:

- password: `operator`
- flag: `HTB{50m371m35_cu570m_p2070c01_423_n07_3n0u9h7}`

That means the challenge is not about breaking encryption or guessing credentials. It is about reading the right stream and noticing that the protocol extension itself leaks the secret material.

## Why This Challenge Is Useful

This is a realistic industrial-security lesson. Internal or operational networks are often assumed to be trusted. Once an attacker reaches that environment, plaintext credentials and custom protocol extensions can fail immediately.

The challenge is worth keeping as a reference point for:

- Modbus/TCP recognition
- ICS traffic triage
- following custom protocol logic in packet captures

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Shush_Protocol"
ls -lah
```

## Study Notes

This challenge is a good reminder that packet captures often solve the problem directly if you ask the right questions. Identify the protocol, isolate the unusual parts, and inspect the payloads before assuming the challenge requires something more advanced.
