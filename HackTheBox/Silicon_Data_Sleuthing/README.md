# Silicon Data Sleuthing

## Overview

This directory contains the local materials and saved solve workflow for the `Silicon Data Sleuthing` challenge on Hack The Box. This is a firmware-forensics task centered on an extracted OpenWrt image. The remote service asks a fixed set of questions, and the solve consists of recovering the required configuration values from the firmware contents.

The saved PoC already answers the live question flow, but the real educational value is in understanding where each answer comes from inside the extracted router data.

## Challenge Profile

- Challenge: `Silicon Data Sleuthing`
- Category: `Forensics`
- Platform: `Hack The Box`
- Saved PoC: `silicon_data_sleuthing_poc.sh`

## Directory Contents

- `challenge.bin`
- `silicon_data_sleuthing_poc.sh`

## First Commands To Run

Review the local files first:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Silicon_Data_Sleuthing"
ls -lah
file challenge.bin
```

Read the saved PoC:

```bash
sed -n "1,220p" "silicon_data_sleuthing_poc.sh"
```

Run the saved answer script:

```bash
chmod +x "silicon_data_sleuthing_poc.sh"
./silicon_data_sleuthing_poc.sh
```

To use it against a fresh spawned instance:

```bash
./silicon_data_sleuthing_poc.sh <HOST> <PORT>
```

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

## Reproduction Commands

Use this sequence for the fast path:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Silicon_Data_Sleuthing"
file challenge.bin
sed -n "1,220p" "silicon_data_sleuthing_poc.sh"
bash "silicon_data_sleuthing_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are practicing firmware triage and OpenWrt-oriented forensics. The PoC gives the final answers quickly, but the more valuable exercise is mapping each answer back to the exact configuration file or metadata source in the extracted image.
