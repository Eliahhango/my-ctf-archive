# picoCTF

## Overview

This directory contains picoCTF challenge archives, local artifacts, and saved proof-of-concept scripts. Most of the folders are built around practical solves for web, pwn, reversing, crypto, general skills, and scripting-style tasks. The READMEs generated here are intended to make each folder useful as a study reference rather than only a flag dump.

## Challenge Folders

- `Bypass_Me`
- `Failure_Failure`
- `Fool_the_Lockout`
- `Heap_Havoc`
- `MY_GIT`
- `No_FA`
- `Printer_Shares`
- `Secure_Password_Database`
- `Smart_Overflow`
- `Undo`
- `bytemancy_1`
- `ping-cmd`

## Recommended Workflow

Use the collection-level directory as an index and each challenge folder as the detailed solve reference. A typical review flow is:

1. List the challenge folders.
2. Open the challenge README.
3. Read the PoC comments first.
4. Run the saved script only after understanding the approach.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF"
ls -lah
find . -maxdepth 2 -name README.md | sort
```
