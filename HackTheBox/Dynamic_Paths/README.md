# Dynamic Paths (Hack The Box) - Professional PoC Writeup

## Challenge Profile

| Field | Value |
|---|---|
| Challenge | Dynamic Paths |
| Category | Coding / Algorithms |
| Vulnerability Class | Deterministic algorithmic protocol |
| Transport | Raw TCP |
| Core task | Minimum path sum on weighted grid |

## Scope And Ethics

This material is for authorized CTF infrastructure only. Do not run this PoC
against systems you do not own or have explicit permission to test.

## Technical Summary

The service sends multiple grid challenges (`t=100` in this instance). For each
round, it provides dimensions `i j` and a flattened list of `i*j` positive
weights. We must compute the minimum path sum from top-left to bottom-right,
moving only right or down, then submit the result before the next round.

## Vulnerable Behavior

1. Challenge logic is deterministic and fully specified in the banner.
2. Each round can be solved with the same dynamic programming recurrence.
3. No anti-automation controls block scripted solving across all rounds.
4. Fast and correct answers reveal the final flag.

## Manual Verification Steps

1. Connect and inspect protocol:

```bash
nc <HOST> <PORT>
```

2. Observe a round with:
- dimensions line: `rows cols`
- values line: flattened grid values
- input prompt: `> `

3. Compute minimum path sum manually for one small round using:

```text
cost[r][c] = min(cost[r-1][c], cost[r][c-1]) + grid[r][c]
```

4. Send the computed value and confirm the server advances to next test.

## Automated PoC

Script:
`dynamic_paths_poc.sh`

### Usage

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Dynamic_Paths"
chmod +x dynamic_paths_poc.sh
./dynamic_paths_poc.sh <host> <port>
```

### Common examples

```bash
./dynamic_paths_poc.sh 154.57.164.69 30173
./dynamic_paths_poc.sh --host 154.57.164.69 --port 30173 --verbose
./dynamic_paths_poc.sh --host 154.57.164.69 --port 30173 --json
```

## Options

- `--host <host>`: target host or IP.
- `--port <port>`: target TCP port.
- `--timeout <seconds>`: socket timeout, default `10`.
- `--round-limit <n>`: max rounds before abort, default `1000`.
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

- The puzzle class is known and repeatable across all rounds.
- Dynamic programming solves each round in linear time over grid cells.
- A script handles timing and volume better than manual interaction.

## Defensive Guidance

- Increase protocol variability to reduce deterministic automation.
- Consider per-round constraints that cannot be reused verbatim.
- Add stronger anti-bot checks for interactive challenge services.

## Result Note

Flag values are instance-specific. The format remains `HTB{...}`.

## Final Flag

Target instance: `154.57.164.69:30173`  
Solved on: `2026-04-02`  
Flag: `HTB{b3h3M07H_5h0uld_H4v3_57ud13D_dYM4m1C_pr09r4mm1n9_70_C47ch_y0u_f27d8bbbe81e40a2803fb2295246bc36}`
