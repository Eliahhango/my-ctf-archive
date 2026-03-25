# Router Web

## Overview

This directory contains challenge files for `Router Web`, but it does not yet contain a saved proof-of-concept script. This README is therefore an investigation guide designed to help someone start from the files in the folder and work toward a solve in a structured way.

## Directory Contents

- `rootfs_extract/`
- `router_web/`
- `router_web.zip`

## First Commands To Run

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Router_Web"
ls -lah
unzip -l "router_web.zip"
```

## Investigation Workflow

Start with a file inventory and search for the places where input is parsed, credentials are stored, or commands are executed. For web and firmware-style challenges, the best early targets are configuration files, web handlers, startup scripts, and extracted root filesystem content.

```bash
find "rootfs_extract" -maxdepth 3 -type f | sort | head -200
find "router_web" -maxdepth 3 -type f | sort | head -200
rg -n "password|passwd|secret|token|flag|exec|system|popen|subprocess|eval" .
```

## Goal For This Folder

Once the challenge is solved, this folder should be brought in line with the rest of the archive by adding a challenge-specific PoC script and replacing this investigation guide with a full walkthrough.
