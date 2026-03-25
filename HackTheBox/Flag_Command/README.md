# Flag Command

## Overview

This directory contains the local materials and manual walkthrough for the `Flag Command` challenge on Hack The Box. This is a web challenge built around a fake terminal adventure interface. The important weakness is that the frontend JavaScript exposes a hidden command path that the backend accepts directly.

The challenge is a strong example of a common web-security lesson: values hidden in client-side code are not secrets.

## Challenge Profile

- Challenge: `Flag Command`
- Category: `Web`
- Platform: `Hack The Box`

## Directory Contents

- `flag_command_poc.sh`

## First Commands To Run

This folder does not include original challenge files. Start by reading the challenge description and the manual walkthrough below, then connect to a fresh challenge instance and reproduce the steps one by one.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Flag_Command"
ls -lah
printf 'Follow the manual walkthrough below against the live service.\n'
```

## How The Application Works

The user sees a browser-based terminal adventure where commands appear to unlock the next stage of the game. That presentation is misleading. The frontend is already fetching the full set of available commands from the backend, including a hidden `secret` command group.

The critical point is that the browser JavaScript checks both:

- the visible commands for the current step
- the hidden commands under `secret`

So a player who inspects the API or JavaScript can skip the intended flow entirely.

## Manual Analysis Workflow

First inspect the frontend code:

```bash
curl -s "http://<HOST>:<PORT>/static/terminal/js/main.js"
```

That reveals the application fetching:

```text
GET /api/options
```

and validating commands against both the normal path and a hidden `secret` path.

Next, request the options directly:

```bash
curl -s "http://<HOST>:<PORT>/api/options"
```

In the response, the hidden command appears under the secret command list.

Finally, send that command directly to the backend:

```bash
curl -s -X POST "http://<HOST>:<PORT>/api/monitor" \
  -H 'Content-Type: application/json' \
  -d '{"command":"Blip-blop, in a pickle with a hiccup! Shmiggity-shmack"}'
```

The backend accepts it immediately and returns the flag.

## Why This Challenge Is Useful

This is a clean demonstration of why client-side secrets do not exist in any meaningful security sense. If the browser can fetch a value, then the user can fetch it too. If the JavaScript can see a hidden command, the attacker can see it as well.

The correct place to enforce sensitive logic is always on the server.

## Optional Archive Reference

The same result can be reached manually with this logic:

1. requests `/api/options`
2. extracts the first secret command from the JSON response
3. sends that command to `/api/monitor`
4. extracts the returned flag

That mirrors the exact logic a manual solve would use, but without relying on a hardcoded hidden string.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Flag_Command"
ls -lah
```

## Study Notes

This challenge is worth revisiting if you are practicing web-application inspection and client-side trust-boundary analysis. It is a useful example of how “hidden” functionality in JavaScript often becomes the actual attack surface.
