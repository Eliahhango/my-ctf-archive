# my-ctf-archive

## Overview

This repository is a personal CTF archive organized by platform or event collection. The goal is not only to store final flags or quick exploits, but to keep each solved challenge reusable as a study reference with local artifacts, proof-of-concept scripts, and readable walkthroughs.

## Top-Level Collections

- `HackTheBox/`
- `picoCTF/`
- `HackerOne/`
- `CTFZone/`

## How This Archive Is Structured

Most challenge folders follow the same pattern:

- original challenge files or extracted artifacts
- a saved `*_poc.sh` script
- a `README.md` explaining the challenge and how to reproduce the solve

The intent is that someone can open any challenge folder later and still understand what the challenge was teaching, which files mattered, and how the solve worked.

## Recommended Workflow

When reviewing the archive, start at the collection level and then move into the specific challenge folder you want to study.

```bash
cd "/home/eliah/Desktop/CTF"
find . -maxdepth 2 -name README.md | sort
```

For a specific challenge, the usual order is:

1. open the challenge README
2. inspect the local files
3. read the top of the saved PoC
4. run the PoC if you want to reproduce the solve

## Notes

This archive mixes static challenges, live remote services, web targets, pwn tasks, hardware artifacts, packet captures, firmware images, and OSINT workflows. Some scripts are fully local, while others depend on a live challenge instance or preserved remote endpoint. The README in each folder should clarify which case applies.
