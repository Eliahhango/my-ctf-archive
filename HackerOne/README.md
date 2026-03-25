# HackerOne

## Overview

This directory contains Hacker101 and HackerOne CTF web challenge solves. These folders are especially useful as case studies in client-side trust issues, SQL injection, access control mistakes, insecure session design, XSS, and broken application workflows.

## Challenge Folders

- `BugDB_v1`
- `BugDB_v2`
- `Micro-CMS`
- `Micro-CMS_2`
- `Micro-CMS_v1`
- `Micro-CMS_v2`
- `Postbook`
- `XSS_Playground`

## Recommended Workflow

Use the collection-level directory as an index and each challenge folder as the detailed solve reference. A typical review flow is:

1. List the challenge folders.
2. Open the challenge README.
3. Read the PoC comments first.
4. Run the saved script only after understanding the approach.

```bash
cd "/home/eliah/Desktop/CTF/HackerOne"
ls -lah
find . -maxdepth 2 -name README.md | sort
```
