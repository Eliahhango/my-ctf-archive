# CTFZone

## Overview

This directory contains CTFZone challenge material and saved solve notes. The current collection is small, but the goal is the same as the other collections: keep enough explanation in each folder that the archive remains useful for review and reuse later.

## Challenge Folders

- `Follow_The_Media`

## Recommended Workflow

Use the collection-level directory as an index and each challenge folder as the detailed solve reference. A typical review flow is:

1. List the challenge folders.
2. Open the challenge README.
3. Read the PoC comments first.
4. Run the saved script only after understanding the approach.

```bash
cd "/home/eliah/Desktop/CTF/CTFZone"
ls -lah
find . -maxdepth 2 -name README.md | sort
```
