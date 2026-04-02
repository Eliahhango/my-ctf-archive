# Stop Drop and Roll (Hack The Box) - Professional PoC Writeup

## Challenge Profile

| Field | Value |
|---|---|
| Challenge | Stop Drop and Roll |
| Category | Misc / Scripting |
| Vulnerability Class | Deterministic protocol automation |
| Transport | Raw TCP |
| Core mapping | `GORGE->STOP`, `PHREAK->DROP`, `FIRE->ROLL` |

## Scope And Ethics

This material is for authorized CTF infrastructure only. Do not run this PoC
against systems you do not own or have explicit permission to test.

## Technical Summary

The service repeatedly prints one or more hazard tokens and asks `What do you do?`.
Each token maps to a fixed action. The required answer is the ordered mapped values
joined with `-`. Because the protocol is deterministic and repeated at scale,
a simple parser solves all rounds and retrieves the flag.

## Vulnerable Behavior

1. Hazard tokens come from a fixed and known set.
2. Mapping rule is explicitly disclosed by the service intro.
3. No randomness or obfuscation is applied to answer derivation.
4. Many rounds can be solved with straightforward automation.

## Manual Verification Steps

1. Connect to the service:

```bash
nc <HOST> <PORT>
```

2. Start the game by answering:

```text
y
```

3. When a scenario appears, map each hazard:

```text
GORGE, FIRE, PHREAK
```

to:

```text
STOP-ROLL-DROP
```

4. Continue until the service returns the flag.

## Automated PoC

Script:
`stop_drop_and_roll_poc.sh`

### Usage

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Stop_Drop_and_Roll"
chmod +x stop_drop_and_roll_poc.sh
./stop_drop_and_roll_poc.sh <host> <port>
```

### Common examples

```bash
./stop_drop_and_roll_poc.sh 154.57.164.68 30395
./stop_drop_and_roll_poc.sh --host 154.57.164.68 --port 30395 --verbose
./stop_drop_and_roll_poc.sh --host 154.57.164.68 --port 30395 --json
```

## Options

- `--host <host>`: target host or IP.
- `--port <port>`: target TCP port.
- `--timeout <seconds>`: socket timeout, default `8`.
- `--round-limit <n>`: max rounds before abort, default `2000`.
- `--json`: machine-readable JSON output.
- `--verbose`: print debug details.
- `-h`, `--help`: show usage help.

## Exit Codes

- `0`: exploit succeeded and flag extracted.
- `2`: invalid CLI arguments.
- `3`: target connectivity failure.
- `4`: protocol parse failure.
- `5`: round limit reached before flag.
- `6`: connection closed before receiving flag.

## Why The Exploit Works

- Protocol responses are purely rule-based.
- Token-to-action mapping is fixed and public.
- Repetitive human workload is trivial for scripts.

## Defensive Guidance

- Avoid deterministic high-volume challenge logic with static mapping.
- Add server-side unpredictability or per-round cryptographic validation.
- Introduce anti-automation controls and stricter timing/state checks.

## Result Note

Flag values may vary by challenge design and deployment policy.

## Final Flag

Target instance: `154.57.164.68:30395`  
Solved on: `2026-04-02`  
Flag: `HTB{1_wiLl_sT0p_dR0p_4nD_r0Ll_mY_w4Y_oUt!}`
