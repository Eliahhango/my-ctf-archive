# Regularity (Hack The Box) - Professional PoC Writeup

## Challenge Profile

| Field | Value |
|---|---|
| Challenge | Regularity |
| Category | Pwn |
| Difficulty | Very Easy |
| Primary dropped file | `pwn_regularity (1).zip` |
| Existing local PoC before this update | Present |
| Core bug class | Stack overflow + control-flow redirection to `jmp rsi` |

## Scope And Ethics

This material is for authorized CTF infrastructure only. Do not run this PoC
against systems you do not own or have explicit permission to test.

## Technical Summary

The binary reads `0x110` bytes into a stack buffer of `0x100` bytes inside its
custom `read` routine:

- `sub rsp, 0x100`
- `mov edx, 0x110`
- `syscall` (`read`)

This overflows past the local buffer and reaches saved return state. The same
binary also contains a direct `jmp rsi` gadget at `0x401041`, and `rsi` still
points to attacker-controlled input buffer after the vulnerable `read` returns.

Exploit flow:
1. Send shellcode at start of input.
2. Pad to RIP offset (`0x100`).
3. Overwrite RIP with `0x401041` (`jmp rsi`).
4. Shellcode executes `open("flag.txt")`, `read`, `write`, `exit`.
5. Parse `HTB{...}` from service output.

## Vulnerable Behavior

1. Stack allocation is smaller than requested input length.
2. No stack canary or other guard in this handcrafted syscall-only binary.
3. Executable stack (`GNU_STACK` is `RWE`) allows direct shellcode execution.
4. Register state (`rsi`) is attacker-controlled at return site.

## Manual Verification Steps

1. Confirm ELF type and fixed base:

```bash
file pwn_regularity/regularity
readelf -h pwn_regularity/regularity
```

2. Confirm executable stack:

```bash
readelf -l pwn_regularity/regularity
```

Look for:

```text
GNU_STACK ... RWE
```

3. Confirm vulnerable `read` and control gadget:

```bash
objdump -d -Mintel pwn_regularity/regularity | sed -n '1,180p'
```

Relevant instructions:

```text
40104b: sub rsp,0x100
401060: mov edx,0x110
401065: syscall
...
401041: jmp rsi
```

4. Send payload (shellcode + RIP overwrite to `0x401041`) and extract flag.

## Automated PoC

Script:
`regularity_poc.sh`

### Usage

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Regularity"
chmod +x regularity_poc.sh
./regularity_poc.sh <host> <port>
```

### Common examples

```bash
./regularity_poc.sh 154.57.164.74 32184
./regularity_poc.sh --host 154.57.164.74 --port 32184 --verbose
./regularity_poc.sh --host 154.57.164.74 --port 32184 --json
```

## Options

- `--host <host>`: target host or IP.
- `--port <port>`: target TCP port.
- `--timeout <seconds>`: socket timeout, default `5`.
- `--json`: machine-readable JSON output.
- `--verbose`: print debug output.
- `-h`, `--help`: show usage help.

## Exit Codes

- `0`: exploit succeeded and flag extracted.
- `2`: invalid CLI arguments.
- `3`: connectivity/request failure.
- `4`: exploit sent but flag not found.

## Why The Exploit Works

- Input length (`0x110`) exceeds local stack buffer (`0x100`).
- Attacker gains RIP control through overflow.
- `jmp rsi` gadget uses already-controlled pointer to payload buffer.
- Executable stack allows shellcode execution without ROP chain complexity.

## Defensive Guidance

- Enforce strict length checks before reading into stack buffers.
- Compile with modern hardening (`-fstack-protector`, PIE, NX, RELRO).
- Avoid executable stack unless absolutely required.
- Prefer safe wrappers over hand-written raw syscall parsers for user input.

## Result Note

Flag values are instance-specific. The format remains `HTB{...}`.

## Final Flag

Target instance: `154.57.164.74:32184`  
Solved on: `2026-04-02`  
Flag: `HTB{juMp1nG_w1tH_tH3_r3gIsT3rS?_868b1ba015353017f809a2ae0d76220c}`
