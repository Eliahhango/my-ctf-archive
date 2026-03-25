# HTB Proxy

## Overview

This directory contains the local materials and saved solve workflow for the `HTB Proxy` challenge on Hack The Box CTF Try Out. This README is written as a practical walkthrough so someone can open the folder, inspect the challenge files, understand the intended weakness, and reproduce the solve with commands that are easy to copy and run.

## Challenge Profile

- Challenge: `HTB Proxy`
- Category: `Web`
- Platform: `Hack The Box CTF Try Out`
- Saved PoC: `htb_proxy_poc.sh`

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

Begin with a short inventory so you can see the original challenge archive, any extracted directories, and the solve script saved in this folder.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/HTB_Proxy"
ls -lah
```

If you want to verify what was originally provided by Hack The Box, inspect the archive contents before extracting or re-extracting them.

```bash
unzip -l "web_htb_proxy.zip"
```

Read the top of the PoC first. The comments there summarize the exact idea used during the solve and usually explain the bug, leak, algorithm, or reversing trick directly.

```bash
sed -n "1,220p" "htb_proxy_poc.sh"
```

Run the PoC after reviewing the notes.

```bash
chmod +x "htb_proxy_poc.sh"
./htb_proxy_poc.sh
```

If the script targets a spawned remote service, you can usually point it at a fresh instance by supplying a host and port.

```bash
./htb_proxy_poc.sh <HOST> <PORT>
```

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

## Reproduction Commands

Use the following command sequence if you want a short and reliable path from opening the folder to reproducing the saved solve.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/HTB_Proxy"
unzip -l "web_htb_proxy.zip"
sed -n "1,220p" "htb_proxy_poc.sh"
bash "htb_proxy_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are practicing `Web` problems. The saved PoC is meant to be the fast path, but the better learning path is to inspect the provided files yourself first, confirm the weakness manually, and then compare your reasoning with the script comments and implementation.
