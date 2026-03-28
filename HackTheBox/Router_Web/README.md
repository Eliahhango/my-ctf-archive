# Router Web

## Overview

This directory contains challenge files for `Router Web`, but it does not yet contain a archived solve notes. This README is therefore an investigation guide designed to help someone start from the files in the folder and work toward a solve in a structured way.

## Directory Contents

- `rootfs_extract/`
- `router_web/`
- `router_web.zip`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Router_Web"
ls -lah
unzip -l "router_web.zip"
```

Useful first inspection commands:

```bash
file 'router_web.zip'
strings -n 5 'router_web.zip' | head -200
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Investigation Workflow

Start with a file inventory and search for the places where input is parsed, credentials are stored, or commands are executed. For web and firmware-style challenges, the best early targets are configuration files, web handlers, startup scripts, and extracted root filesystem content.

```bash
find "rootfs_extract" -maxdepth 3 -type f | sort | head -200
find "router_web" -maxdepth 3 -type f | sort | head -200
rg -n "password|passwd|secret|token|flag|exec|system|popen|subprocess|eval" .
```

## Goal For This Folder

Once the challenge is solved, this folder should be brought in line with the rest of the archive by adding a challenge-specific archived notes script and replacing this investigation guide with a full walkthrough.
