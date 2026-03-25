# my-ctf-archive

## Overview

This repository is a personal CTF archive organized by platform or event collection. The goal is not only to store final flags, but to keep each solved challenge reusable as a study reference with local artifacts, readable walkthroughs, and manual reproduction steps.

## Top-Level Collections

- `HackTheBox/`
- `picoCTF/`
- `HackerOne/`
- `CTFZone/`

## How This Archive Is Structured

Most challenge folders follow the same pattern:

- original challenge files or extracted artifacts
- optional archived helper notes or old automation kept for reference
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
3. follow the manual commands in order
4. compare your work with any archived helper notes only after finishing the manual path

## Notes

This archive mixes static challenges, live remote services, web targets, pwn tasks, hardware artifacts, packet captures, firmware images, and OSINT workflows. Some folders still contain older helper scripts for archival reasons, but the README in each folder is now intended to stand on its own with a manual, step-by-step workflow.
