# Silicon Data Sleuthing

## Overview

This directory contains the local materials and manual walkthrough for the `Silicon Data Sleuthing` challenge on Hack The Box. This is a firmware-forensics task centered on an extracted OpenWrt image. The remote service asks a fixed set of questions, and the solve consists of recovering the required configuration values from the firmware contents.

The archived notes in this folder preserve the final answer flow, but the real educational value is understanding where each answer comes from inside the extracted router data.

## Challenge Profile

- Challenge: `Silicon Data Sleuthing`
- Category: `Forensics`
- Platform: `Hack The Box`

## Directory Contents

- `challenge.bin`
- `silicon_data_sleuthing_poc.sh`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Silicon_Data_Sleuthing"
ls -lah
```

Useful first inspection commands:

```bash
file 'challenge.bin'
strings -n 5 'challenge.bin' | head -200
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Investigation Approach

The firmware image is an OpenWrt-style system dump. In challenges like this, the important workflow is:

1. identify the firmware format
2. extract the filesystem
3. search configuration files
4. recover credentials and service settings
5. answer the remote questionnaire

The most useful early tools are usually:

```bash
binwalk challenge.bin
binwalk -e challenge.bin
find . -maxdepth 3 -type f | sort | head -200
```

Once the filesystem is extracted, typical OpenWrt locations to inspect are:

- `/etc/openwrt_release`
- `/etc/banner`
- `/etc/passwd`
- `/etc/shadow`
- `/etc/config/network`
- `/etc/config/wireless`
- `/etc/config/firewall`
- `/etc/ppp/`

## What Had To Be Recovered

The challenge required these values:

- OpenWrt version: `23.05.0`
- Linux kernel version: `5.15.134`
- Root password hash:
  `root:$1$YfuRJudo$cXCiIJXn9fWLIt8WY2Okp1:19804:0:99999:7:::`
- PPPoE username: `yohZ5ah`
- PPPoE password: `ae-h+i$i^Ngohroorie!bieng6kee7oh`
- WiFi SSID: `VLT-AP01`
- WiFi password: `french-halves-vehicular-favorable`
- WAN to LAN forwarded ports: `1778,2289,8088`

These are classic router-forensics artifacts. None of them require guessing if the filesystem is extracted correctly and the right OpenWrt configuration files are inspected.

## Manual Search Commands

If you want to reproduce the forensic work manually, these are good commands to use after extraction:

```bash
find _challenge.bin.extracted -type f | sort | head -200
rg -n "OpenWrt|DISTRIB|VERSION|KERNEL" _challenge.bin.extracted
rg -n "pppoe|username|password" _challenge.bin.extracted
rg -n "ssid|key|wifi|wireless" _challenge.bin.extracted
rg -n "redirect|src_dport|dest_port|wan|lan" _challenge.bin.extracted
```

If the extraction directory has a different name on your system, replace `_challenge.bin.extracted` accordingly.

## Why This Challenge Is Useful

This challenge is good practice because it mirrors a very realistic firmware-review workflow:

- identify the OS and version
- inspect authentication data
- recover network credentials
- enumerate firewall rules and forwarding behavior

In real assessments, this kind of information often leads directly to credential reuse, lateral movement, remote access, or administrative takeover of embedded systems.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Silicon_Data_Sleuthing"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `HTB{Y0u'v3_m4st3r3d_0p3nWRT_d4t4_3xtr4ct10n!!_ccc7c86e99701a06e8997bef3acd71f8}`

## Study Notes

This challenge is worth revisiting if you are practicing firmware triage and OpenWrt-oriented forensics. The more valuable exercise is mapping each answer back to the exact configuration file or metadata source in the extracted image, then using the archived notes only as a cross-check.
