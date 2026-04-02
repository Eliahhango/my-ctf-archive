# TunnelMadness (Hack The Box) - Professional PoC Writeup

## Challenge Profile

| Field | Value |
|---|---|
| Challenge | TunnelMadness |
| Category | Reversing |
| Transport | Interactive TCP |
| Provided file in main CTF dir | `rev_tunnelmadness (1).zip` |
| Core artifact | Recovered route string replay |

## Scope And Ethics

This material is for authorized CTF infrastructure only. Do not run this PoC
against systems you do not own or have explicit permission to test.

## Technical Summary

The binary contains a `20x20x20` maze in static data and uses movement commands
`L/R/F/B/U/D` to navigate it. After reversing the movement mapping and solving
the maze path offline, the valid route is replayed to the remote service to
reach the success state and receive the real flag.

The new archive in main directory:
`/home/eliah/Desktop/CTF/rev_tunnelmadness (1).zip`
is byte-identical to the existing one in this challenge folder.

## Vulnerable Behavior

1. Maze state and movement semantics are recoverable from the binary.
2. Success condition depends only on providing the correct movement sequence.
3. Route replay bypasses manual in-terminal navigation complexity.
4. Remote service reveals final flag once goal state is reached.

## Manual Verification Steps

1. Inspect provided archive and binary:

```bash
cd "/home/eliah/Desktop/CTF"
unzip -l "rev_tunnelmadness (1).zip"
unzip -o "rev_tunnelmadness (1).zip" -d /tmp/tunnel_new
strings -n 5 /tmp/tunnel_new/rev_tunnelmadness/tunnel | head -200
```

2. Reverse movement mapping from binary logic:
- `B` = x-
- `R` = x+
- `L` = y-
- `F` = y+
- `D` = z-
- `U` = z+

3. Use recovered shortest route:

```text
UUURFURURRFRRFFUUFURRUFUFFRFUFUUUUFFRRUUUFURFDFFUFFRRRRRFRR
```

4. Replay route to remote prompt `Direction (L/R/F/B/U/D/Q)?` and read flag.

## Automated PoC

Script:
`tunnelmadness_poc.sh`

### Usage

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/TunnelMadness"
chmod +x tunnelmadness_poc.sh
./tunnelmadness_poc.sh <host> <port>
```

### Common examples

```bash
./tunnelmadness_poc.sh 154.57.164.74 32519
./tunnelmadness_poc.sh --host 154.57.164.74 --port 32519 --verbose
./tunnelmadness_poc.sh --host 154.57.164.74 --port 32519 --json
```

## Options

- `--host <host>`: target host or IP.
- `--port <port>`: target TCP port.
- `--path <moves>`: override route string.
- `--timeout <seconds>`: socket timeout, default `8`.
- `--json`: machine-readable JSON output.
- `--verbose`: print debug details.
- `-h`, `--help`: show usage help.

## Exit Codes

- `0`: exploit succeeded and flag extracted.
- `2`: invalid CLI arguments.
- `3`: connectivity failure.
- `4`: interaction/prompt parse failure.
- `5`: route replay completed but no flag found.

## Why The Exploit Works

- Reversing reveals the exact movement semantics.
- Maze route can be solved offline once map representation is understood.
- Remote challenge accepts deterministic command replay.

## Defensive Guidance

- Do not embed full navigation model and semantics plainly in shipped binaries.
- Add runtime integrity checks and server-side validation complexity.
- Avoid static success paths that can be replayed verbatim.

## Result Note

Flag values are instance-specific. The format remains `HTB{...}`.

## Final Flag

Target instance: `154.57.164.74:32519`  
Solved on: `2026-04-02`  
Flag: `HTB{tunn3l1ng_ab0ut_in_3d_3af491ddea77f37e81d0adc18e87e8db}`
