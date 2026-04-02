# CTFZone

## Overview

This directory contains CTFZone challenge material and challenge walkthrough notes. The current collection is small, but the goal is the same as the other collections: keep enough explanation in each folder that the archive remains useful for review and reuse later.

## Challenge Folders

- `Follow_The_Media`
- `Phantom_Recursion`

## Recommended Workflow

Use the collection-level directory as an index and each challenge folder as the detailed solve reference. A typical review flow is:

1. List the challenge folders.
2. Open the challenge README.
3. Inspect the local description and supporting files.
4. Follow the manual investigation steps in the README.

```bash
cd "/home/eliah/Desktop/CTF/CTFZone"
ls -lah
find . -maxdepth 2 -name README.md | sort
```
