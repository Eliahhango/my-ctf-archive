# Void (Hack The Box) - Professional PoC Writeup

## Challenge Profile

| Field | Value |
|---|---|
| Challenge | Void |
| Category | Pwn |
| Difficulty | Medium |
| Primary dropped file | `pwn_void (1).zip` |
| Existing local PoC before this update | Present |
| Core bug class | Stack overflow + ret2dlresolve |

## Scope And Ethics

This material is for authorized CTF infrastructure only. Do not run this PoC
against systems you do not own or have explicit permission to test.

## Technical Summary

The binary is intentionally minimal. It has a single vulnerable function:

```c
void vuln() {
    char buf[0x40];
    read(0, buf, 0xc8);
}
```

Because `0xc8` bytes are read into a `0x40`-byte stack buffer, return control
is reachable at offset `72` (`64` buffer + `8` saved `rbp`).

There is no direct `win()` function and only one PLT import (`read`). A normal
ret2win or standard libc-leak path is not available, so the intended technique
is `ret2dlresolve`:

1. Stage 1 overflows stack and sets up a small ROP chain.
2. ROP calls `read` again to load forged resolver data.
3. Chain invokes PLT resolver trampoline (`plt0`).
4. Fake relocation/symbol records resolve `system` at runtime.
5. Resolved call executes `system("cat flag.txt")`.

## Vulnerable Behavior

1. Stack overflow via oversized `read` into fixed local buffer.
2. No stack canary in challenge binary.
3. Very small import surface encourages loader-abuse exploitation.
4. Dynamic linker metadata can be forged under attacker control.

## Manual Verification Steps

1. Confirm vulnerable instructions and stack layout:

```bash
objdump -d -Mintel challenge/void | sed -n '120,220p'
```

Relevant instructions:

```text
401126: sub rsp,0x40
40112e: mov edx,0xc8
40113b: call read@plt
```

2. Confirm dynamic relocations/imports are minimal:

```bash
readelf -r challenge/void
readelf -s challenge/void
```

Key observation:

```text
.rela.plt contains only read@GLIBC_2.2.5
```

3. Confirm useful gadgets:

```bash
HackTheBox/Void/.venv/bin/ROPgadget --binary challenge/void --only 'pop|ret'
```

Notable gadgets:

```text
0x4011bb : pop rdi ; ret
0x4011b9 : pop rsi ; pop r15 ; ret
0x401016 : ret
```

4. Run exploit (two-stage payload: overflow + forged resolver structures).

5. Extract `HTB{...}` from output.

## Automated PoC

Script:
`void_poc.sh`

### Usage

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Void"
chmod +x void_poc.sh
./void_poc.sh <host> <port>
```

### Common examples

```bash
./void_poc.sh 154.57.164.77 31676
./void_poc.sh --host 154.57.164.77 --port 31676 --verbose
./void_poc.sh --host 154.57.164.77 --port 31676 --json
```

## Options

- `--host <host>`: target host or IP.
- `--port <port>`: target TCP port.
- `--timeout <seconds>`: socket timeout, default `8`.
- `--stage-delay <seconds>`: delay between stage1 and stage2, default `0.20`.
- `--json`: machine-readable JSON output.
- `--verbose`: print debug output.
- `-h`, `--help`: show usage help.

## Exit Codes

- `0`: exploit succeeded and flag extracted.
- `2`: invalid CLI arguments.
- `3`: connectivity/protocol failure.
- `4`: exploit sent but flag not found.

## Why The Exploit Works

- Overflow gives RIP control despite tiny program logic.
- Direct ret2win is unavailable due missing target functionality.
- Dynamic resolver (`plt0`) can be abused with crafted relocation entries.
- Runtime resolution of `system` provides a command execution primitive.

## Defensive Guidance

- Enforce strict read-size limits tied to destination buffer size.
- Enable full hardening (`-fstack-protector`, PIE, RELRO, FORTIFY).
- Consider seccomp/sandboxing to constrain post-exploitation impact.
- Treat dynamic linker attack surface as part of threat model.

## Result Note

Flag values are instance-specific. The format remains `HTB{...}`.

## Final Flag

Target instance: `154.57.164.77:31676`  
Solved on: `2026-04-02`  
Flag: `HTB{pwnt00l5_h0mep4g3_15_u54ful}`
