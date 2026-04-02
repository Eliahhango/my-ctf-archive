#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - Silicon Data Sleuthing
# Type: Firmware-forensics questionnaire automation (OpenWrt artifact answers)
#
# This script is intended for authorized CTF infrastructure only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEOUT=10

HOST=""
PORT=""
TIMEOUT="${DEFAULT_TIMEOUT}"
JSON_OUTPUT=0
VERBOSE=0

usage() {
  cat <<USAGE
Usage:
  ${SCRIPT_NAME} <host> <port>
  ${SCRIPT_NAME} --host <host> --port <port> [options]

Options:
  --host <host>            Target host/IP
  --port <port>            Target TCP port
  --timeout <seconds>      Socket timeout (default: ${DEFAULT_TIMEOUT})
  --json                   Print result as JSON
  --verbose                Enable debug output
  -h, --help               Show this help message

Exit codes:
  0  Success (flag extracted)
  1  Generic failure
  2  Invalid arguments
  3  Connectivity/protocol failure
  4  Answers sent but flag not found
USAGE
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

log_error() {
  printf '[-] %s\n' "$*" >&2
}

parse_args() {
  local positional=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host)
        HOST="${2:-}"
        shift 2
        ;;
      --port)
        PORT="${2:-}"
        shift 2
        ;;
      --timeout)
        TIMEOUT="${2:-}"
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
      -* )
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

  if [[ -z "${HOST}" && ${#positional[@]} -ge 1 ]]; then
    HOST="${positional[0]}"
  fi
  if [[ -z "${PORT}" && ${#positional[@]} -ge 2 ]]; then
    PORT="${positional[1]}"
  fi

  if [[ -z "${HOST}" || -z "${PORT}" ]]; then
    log_error "Host and port are required."
    usage >&2
    exit 2
  fi

  if ! [[ "${PORT}" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
    log_error "Invalid port: ${PORT}"
    exit 2
  fi

  if ! [[ "${TIMEOUT}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    log_error "Invalid timeout: ${TIMEOUT}"
    exit 2
  fi
}

main() {
  parse_args "$@"

  log_info "Target: ${HOST}:${PORT}"
  log_debug "Submitting known OpenWrt artifact answers in prompt order"

  python3 - "$HOST" "$PORT" "$TIMEOUT" "$JSON_OUTPUT" "$VERBOSE" <<'PY'
import json
import re
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])
timeout = float(sys.argv[3])
json_output = sys.argv[4] == "1"
verbose = sys.argv[5] == "1"

answers = [
    "23.05.0",
    "5.15.134",
    "root:$1$YfuRJudo$cXCiIJXn9fWLIt8WY2Okp1:19804:0:99999:7:::",
    "yohZ5ah",
    "ae-h+i$i^Ngohroorie!bieng6kee7oh",
    "VLT-AP01",
    "french-halves-vehicular-favorable",
    "1778,2289,8088",
]


def emit_debug(msg: str) -> None:
    if verbose and not json_output:
        print(f"[D] {msg}", file=sys.stderr)


def fail(code: int, msg: str) -> None:
    if json_output:
        print(json.dumps({"ok": False, "error": msg, "target": f"{host}:{port}"}))
    else:
        print(f"[-] {msg}", file=sys.stderr)
    raise SystemExit(code)


try:
    sock = socket.create_connection((host, port), timeout=timeout)
except Exception as exc:
    fail(3, f"Connection failed: {exc}")

try:
    sock.settimeout(timeout)
    buffer = b""

    for idx, answer in enumerate(answers, start=1):
        while b"> " not in buffer:
            try:
                chunk = sock.recv(4096)
            except socket.timeout:
                fail(3, f"Timeout waiting for prompt #{idx}")
            if not chunk:
                fail(3, f"Connection closed before prompt #{idx}")
            buffer += chunk

        emit_debug(f"Prompt #{idx} reached; sending answer")
        sock.sendall(answer.encode() + b"\n")
        buffer = b""

    chunks = []
    while True:
        try:
            data = sock.recv(4096)
        except socket.timeout:
            break
        if not data:
            break
        chunks.append(data)
finally:
    sock.close()

text = b"".join(chunks).decode("latin1", errors="ignore")
match = re.search(r"HTB\{[^}]+\}", text)

if not match:
    if verbose and not json_output:
        print("[D] Response preview:", file=sys.stderr)
        print(text[:1000], file=sys.stderr)
    fail(4, "Flag pattern not found in target response")

flag = match.group(0)

if json_output:
    print(json.dumps({
        "ok": True,
        "target": f"{host}:{port}",
        "answers_sent": len(answers),
        "flag": flag,
    }))
else:
    print(flag)
PY
}

main "$@"
