# HTB Proxy (Hack The Box) - Professional PoC Writeup

## Challenge Profile

| Field | Value |
|---|---|
| Challenge | HTB Proxy |
| Category | Web |
| Difficulty | Medium |
| Primary dropped file | `web_htb_proxy (1).zip` |
| Core chain | Request smuggling + backend command injection |

## Scope And Ethics

This material is for authorized CTF infrastructure only. Do not run this PoC
against systems you do not own or have explicit permission to test.

## Technical Summary

The public service is a custom HTTP proxy with weak request parsing and weak
host/filter checks. A smuggled second request can hit hidden backend endpoint
`/flushInterface`, which executes shell commands through `ip-wrapper` with
unsafely interpolated interface input.

Exploit flow:
1. Read pod IP from `/server-status`.
2. Convert to dash DNS form: `10-244-x-y.default.pod.cluster.local:5000`.
3. Smuggle second `POST /flushInterface` request.
4. Inject shell command to overwrite proxy homepage with flag content.
5. Fetch `/` and extract `HTB{...}`.

## Vulnerable Behavior

1. Host blacklist checks raw string patterns only.
2. Internal request parser splits by repeated `\r\n\r\n` in unsafe manner.
3. Hidden backend route accepts attacker-controlled interface input.
4. Backend command execution path allows shell injection.

## Manual Verification Steps

1. Read pod IP:

```bash
printf 'GET /server-status HTTP/1.1\r\nHost: x:1\r\nConnection: close\r\n\r\n' | nc <PROXY_IP> <PROXY_PORT>
```

2. Build internal backend host:

```text
10.244.36.130 -> 10-244-36-130.default.pod.cluster.local:5000
```

3. Smuggle second request containing:

```json
{"interface":";cat${IFS}/flag*.txt>/app/proxy/includes/index.html"}
```

4. Request `/` from public proxy and capture rendered flag.

## Automated PoC

Script:
`htb_proxy_poc.sh`

### Usage

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/HTB_Proxy"
chmod +x htb_proxy_poc.sh
./htb_proxy_poc.sh 154.57.164.74 30548
```

### Common examples

```bash
./htb_proxy_poc.sh 154.57.164.74 30548
./htb_proxy_poc.sh --proxy-ip 154.57.164.74 --proxy-port 30548 --verbose
./htb_proxy_poc.sh --proxy-ip 154.57.164.74 --proxy-port 30548 --pod-ip 10.244.36.130
./htb_proxy_poc.sh --proxy-ip 154.57.164.74 --proxy-port 30548 --json
```

## Options

- `--proxy-ip <ip>`: public proxy host/IP.
- `--proxy-port <port>`: public proxy port.
- `--pod-ip <ip>`: internal pod IP override (otherwise auto-detected).
- `--inject <cmd>`: interface injection command.
- `--timeout <seconds>`: socket timeout, default `5`.
- `--send-retries <n>`: smuggle send attempts, default `5`.
- `--fetch-retries <n>`: homepage polling attempts, default `12`.
- `--sleep <seconds>`: delay between attempts, default `0.5`.
- `--json`: machine-readable JSON output.
- `--verbose`: print debug details.
- `-h`, `--help`: show usage help.

## Exit Codes

- `0`: exploit succeeded and flag extracted.
- `2`: invalid CLI arguments.
- `3`: connectivity/request failure.
- `4`: pod IP detection failed.
- `5`: exploit sent but flag not observed.

## Why The Exploit Works

- Public proxy applies brittle string-based request filtering.
- Request boundary handling lets attacker smuggle backend request.
- Backend handler uses unsafe command execution with user input.
- Flag exfiltration uses writable static page path exposed by proxy.

## Defensive Guidance

- Use robust HTTP parsing with strict single-request boundaries.
- Enforce backend access controls independent of frontend proxy logic.
- Never pass untrusted input into shell commands.
- Implement allowlisted interfaces and safe subprocess APIs.

## Result Note

Flag values are instance-specific. The format remains `HTB{...}`.

## Final Flag

Target instance: `154.57.164.74:30548`  
Solved on: `2026-04-02`  
Flag: `HTB{r3inv3nting_th3_wh331_c4n_cr34t3_h34dach35_234afa2a75f15ccfbec626fd76516d49}`
