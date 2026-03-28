# Printer Shares

## Overview

This directory contains the local materials and manual walkthrough for the `Printer Shares` challenge from `picoCTF 2026`. The goal of this README is to make the folder immediately useful to someone reviewing the archive later: what the challenge was about, what files matter, how the solve works at a high level, and which commands to run first.

## Challenge Profile

- Challenge: `Printer Shares`
- Category: `General Skills`
- Collection: `picoCTF`
- Event or Platform: `picoCTF 2026`
- Difficulty: `Medium`
- Author: `JANICE HE`

## Directory Contents

- `dummy.txt`
- `flag.txt`
- `printer_shares_poc.sh`
- `share_dump/`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Printer_Shares"
ls -lah
```

Useful first inspection commands:

```bash
sed -n '1,220p' 'dummy.txt'
sed -n '1,220p' 'flag.txt'
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Walkthrough

Challenge Name: Printer Shares
Category: General Skills
Difficulty: Medium
Event: picoCTF 2026
Author: JANICE HE

### Description

"Oops! Someone accidentally sent an important file to a network
printer, can you retrieve it from the print server?"

### Given information from the challenge

Printer port shown in the prompt: 55031
Suggested command in the prompt:
nc -vz mysterious-sea.picoctf.net 55031

### Core lesson

Not every service gives you a banner or responds to random text.
A lot of network services stay quiet until you speak the correct protocol.

In this challenge, the port check is only the starting point.
The real task is to recognize that the host exposes a printer-related file
share over SMB and then use an SMB client to browse and retrieve the file.

### Real-world analogy

In an internal network, a printer or print server may expose shared storage
for scanned documents, queued jobs, or logs. If guest access is enabled,
sensitive documents can leak even when no software exploit is involved.

That is a very real security lesson:
misconfiguration alone can expose confidential data.

### High-level attack plan

1. Confirm the challenge port is reachable.
2. Enumerate shares on the host with smbclient.
3. Identify the public guest-accessible share.
4. List files in that share.
5. Download flag.txt and read it locally.

### Step 1: Confirm the challenge port is open.

Manual command:
nc -vz mysterious-sea.picoctf.net 55031

Reason:
This verifies that the service is alive and that we can reach the challenge
host on the forwarded port.

Important observation:
Reaching a port does not mean it will reply to plain text. Many services do
nothing until the client speaks the right protocol.

### Step 2: Enumerate the available SMB shares.

Manual command:
smbclient -L //mysterious-sea.picoctf.net -p 55031 -N

Reason:
-L asks smbclient to list the remote shares.
-p 55031 tells it to use the forwarded challenge port instead of default SMB
ports.
-N means "no password", which tests guest/anonymous access.

In the solved instance, this reveals a public share named:
shares

### Step 3: Connect to the public share and list files.

Manual command:
smbclient //mysterious-sea.picoctf.net/shares -p 55031 -N -m SMB3 -c 'ls'

Reason:
We connect directly to the "shares" share and request a directory listing.
Using -m SMB3 keeps the client on a modern dialect that works cleanly through
the challenge port forward.

The listing shows:
- dummy.txt
- flag.txt

### Step 4: Download the flag file.

Manual command:
smbclient //mysterious-sea.picoctf.net/shares -p 55031 -N -m SMB3 -c 'get flag.txt'

Reason:
Once a share is exposed to guests, file retrieval is as simple as using the
normal client command. There is no memory corruption here. The weakness is
access control: the file is available to anyone who can authenticate as guest.

### Step 5: Read the recovered file locally.

Manual command:
sed -n '1,20p' flag.txt

Reason:
After download, the file is just a normal local file in our challenge folder,
so reading it gives the flag.

Real-world security concept:
This is a classic "sensitive file exposure" case caused by an overly
permissive share. In a real environment, an admin should:
- disable guest access
- restrict share permissions
- isolate printer storage from general network users
- audit queued document retention

### Flag obtained

picoCTF{5mb_pr1nter_5h4re5_9fc5e085}

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Printer_Shares"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `picoCTF{5mb_pr1nter_5h4re5_9fc5e085}`

## Study Notes

This folder is best used as a practical study reference for `General Skills`-style problems. Work through the manual inspection and exploitation steps first, then compare your reasoning against the archived solve notes if you want an extra cross-check.
