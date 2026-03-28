# HTB Proxy

## Overview

This directory contains the local materials and manual walkthrough for the `HTB Proxy` challenge on Hack The Box CTF Try Out. This README is written as a practical walkthrough so someone can open the folder, inspect the challenge files, understand the intended weakness, and reproduce the solve with commands that are easy to copy and run.

## Challenge Profile

- Challenge: `HTB Proxy`
- Category: `Web`
- Platform: `Hack The Box CTF Try Out`

## Directory Contents

- `Dockerfile`
- `build_docker.sh`
- `challenge/`
- `config/`
- `entrypoint.sh`
- `flag.txt`
- `htb_proxy_poc.sh`
- `web_htb_proxy.zip`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/HTB_Proxy"
ls -lah
unzip -l "web_htb_proxy.zip"
```

Useful first inspection commands:

```bash
sed -n '1,220p' 'Dockerfile'
sed -n '1,220p' 'build_docker.sh'
sed -n '1,220p' 'entrypoint.sh'
sed -n '1,220p' 'flag.txt'
file 'web_htb_proxy.zip'
strings -n 5 'web_htb_proxy.zip' | head -200
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Walkthrough

Challenge: HTB Proxy
Category: Web
Platform: Hack The Box CTF Try Out

### Scenario summary

The target exposes a custom HTTP proxy. The source code shows a hidden backend
service with two routes:
1. POST /getAddresses
2. POST /flushInterface

The backend route /flushInterface is dangerous because it passes user input
into the npm package "ip-wrapper", and that package uses child_process.exec()
with the interface name inserted directly into a shell command:

ip address flush dev <user_input>

That means command injection is possible.

### Real-world concept

This is a chain exploit, which is common in web security:
- Step 1: bypass proxy routing restrictions
- Step 2: bypass request filtering
- Step 3: exploit backend command injection
- Step 4: move the sensitive file into a place we can read back safely

Why we do not simply "cat /flag" and expect it in the HTTP response:
The backend route /flushInterface returns only a generic success/error JSON
response. Even if the command runs, its stdout is not reflected back to us in a
useful way. So instead, we overwrite the proxy's static homepage file with the
flag, then request "/" and read the flag from there.

### Key observations from the source

1. The proxy blocks hosts that contain these raw substrings:
localhost, 0.0.0.0, 127., 172., 192., 10.
But it only checks the raw Host string, not the IP after DNS resolution.

2. The /server-status route reveals the pod IP:
10.244.40.71

3. Kubernetes pod DNS lets us reference that IP in a dash-encoded hostname:
10-244-40-71.default.pod.cluster.local
This avoids the raw "10." blacklist while still resolving to the internal
backend.

4. The proxy blocks URLs containing "flushinterface", but only for the first
parsed request. The parser is flawed because it splits the whole request on
every "\r\n\r\n". We can therefore smuggle a second request after an empty
first body.

Smuggling layout:
POST /getAddresses HTTP/1.1
Host: internal-backend
Content-Length: 0
Content-Type: application/json

<empty body>

POST /flushInterface HTTP/1.1
Host: internal-backend
Content-Type: application/json
Content-Length: ...

{"interface":";cat${IFS}/flag*.txt>/app/proxy/includes/index.html"}

Why ${IFS} is used:
The backend input validator rejects literal spaces in the interface name.
${IFS} expands to shell whitespace when exec() invokes /bin/sh -c internally.

### Manual commands / logic

1. Confirm the pod IP:
curl or raw GET to /server-status

2. Route to the backend using:
Host: 10-244-40-71.default.pod.cluster.local:5000

3. Smuggle a second POST request to /flushInterface

4. Command injection payload:
;cat${IFS}/flag*.txt>/app/proxy/includes/index.html

5. Request "/" from the proxy and extract the flag

Flag obtained on this instance:
HTB{r3inv3nting_th3_wh331_c4n_cr34t3_h34dach35_41808acdd4d47662f43de96acebc2b31}

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/HTB_Proxy"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `HTB{r3inv3nting_th3_wh331_c4n_cr34t3_h34dach35_41808acdd4d47662f43de96acebc2b31}`

## Study Notes

This challenge is worth revisiting if you are practicing `Web` problems. Inspect the routes and source manually first, confirm the weakness yourself, and only then compare your reasoning against the archived solve notes.
