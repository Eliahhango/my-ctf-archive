# picoCTF

## Overview

This directory contains picoCTF challenge archives, local artifacts, and challenge-specific walkthroughs. Most of the folders are built around practical solves for web, pwn, reversing, crypto, general skills, and scripting-style tasks. The READMEs are intended to make each folder useful as a study reference rather than only a flag dump.

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
3. Inspect the local files that came with the challenge.
4. Follow the manual commands in the README until you reach the answer.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF"
ls -lah
find . -maxdepth 2 -name README.md | sort
```
