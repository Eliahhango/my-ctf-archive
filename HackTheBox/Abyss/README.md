# Abyss (Hack The Box) - Professional PoC Writeup

## Challenge Profile

| Field | Value |
|---|---|
| Challenge | Abyss |
| Category | Pwn |
| Difficulty | Easy |
| Primary dropped file | `pwn_abyss (1).zip` |
| Existing local PoC before this update | Present |
| Core bug class | Parser-driven stack overflow from unterminated `read()` data |

## Scope And Ethics

This material is for authorized CTF infrastructure only. Do not run this PoC
against systems you do not own or have explicit permission to test.

## Technical Summary

The login parser reads raw bytes into a fixed stack buffer and then copies
`USER` and `PASS` fields with loops that only stop at `\0`:

```c
while (buf[i] != '\0') {
    pass[i - 5] = buf[i];
    i++;
}
```

Because `read(0, buf, sizeof(buf))` does not append a null terminator, a full
`PASS` payload with no `\0` causes the copy loop to walk beyond intended input,
corrupting adjacent stack state including saved return control.

Exploit flow:
1. Send command `LOGIN` (`0`).
2. Send crafted `USER` payload.
3. Send 512-byte `PASS` body (no null byte) to trigger overflow.
4. Partially overwrite saved RIP low bytes with `0x4014eb`.
5. Execution re-enters `cmd_read()` at the `logged_in` test branch point.
6. Send `flag.txt` as filename and capture `HTB{...}` from output.

## Vulnerable Behavior

1. Raw `read()` input is treated as null-terminated text without enforcing a terminator.
2. Unbounded parser loops copy attacker-controlled bytes until accidental `\0`.
3. Stack corruption in `cmd_login()` permits saved return-address overwrite.
4. Control-flow redirection bypasses intended authentication gate in normal path.

## Manual Verification Steps

1. Inspect vulnerable source:

```bash
sed -n '1,260p' pwn_abyss/challenge/source.c
```

2. Inspect login parser and read gate in disassembly:

```bash
objdump -d -Mintel pwn_abyss/challenge/abyss | sed -n '280,520p'
```

Key locations:

```text
cmd_login: 0x401296
cmd_read:  0x4014a9
0x4014eb:  test eax,eax   ; logged_in check site used by partial overwrite
```

3. Run the exploit chain against target and extract flag.

## Automated PoC

Script:
`abyss_poc.sh`

### Usage

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Abyss"
chmod +x abyss_poc.sh
./abyss_poc.sh <host> <port>
```

### Common examples

```bash
./abyss_poc.sh 154.57.164.69 32244
./abyss_poc.sh --host 154.57.164.69 --port 32244 --verbose
./abyss_poc.sh --host 154.57.164.69 --port 32244 --json
```

## Options

- `--host <host>`: target host or IP.
- `--port <port>`: target TCP port.
- `--timeout <seconds>`: socket timeout, default `8`.
- `--stage-delay <sec>`: delay between protocol stages, default `0.6`.
- `--json`: machine-readable JSON output.
- `--verbose`: print debug output.
- `-h`, `--help`: show usage help.

## Exit Codes

- `0`: exploit succeeded and flag extracted.
- `2`: invalid CLI arguments.
- `3`: connectivity/protocol failure.
- `4`: exploit sent but flag not found.

## Why The Exploit Works

- Login parser relies on `\0` termination but uses raw `read()`.
- Crafted payload keeps parser copying out-of-bounds into stack metadata.
- Partial RIP overwrite avoids null-byte constraints of full 64-bit address writes.
- Redirecting to `0x4014eb` lands in `cmd_read()` path after auth decision point.

## Defensive Guidance

- Never process raw `read()` buffers as C strings without explicit termination.
- Track and enforce exact byte lengths when parsing protocol fields.
- Use bounded copy routines and strict field-size checks.
- Add compiler/runtime hardening (stack canaries, PIE, full RELRO, stronger control-flow protections).

## Result Note

Flag values are instance-specific. The format remains `HTB{...}`.

## Final Flag

Target instance: `154.57.164.69:32244`  
Solved on: `2026-04-02`  
Flag: `HTB{sH0u1D_h4v3-NU11-t3rmIn4tEd_buf!_d6b1090b1d62b29d8e894de757982644}`
