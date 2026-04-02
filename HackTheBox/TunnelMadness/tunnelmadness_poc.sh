#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - TunnelMadness
# Type: Reversing + route replay over interactive TCP service
#
# This script is intended for authorized CTF infrastructure only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEOUT=8
readonly DEFAULT_PATH="UUURFURURRFRRFFUUFURRUFUFFRFUFUUUUFFRRUUUFURFDFFUFFRRRRRFRR"

HOST=""
PORT=""
PATH_STR="${DEFAULT_PATH}"
TIMEOUT="${DEFAULT_TIMEOUT}"
JSON_OUTPUT=0
VERBOSE=0

usage() {
  cat <<EOF
Usage:
  ${SCRIPT_NAME} <host> <port>
  ${SCRIPT_NAME} --host <host> --port <port> [options]

Options:
  --host <host>         Target host or IP address
  --port <port>         Target TCP port
  --path <moves>        Movement route string (default: recovered shortest route)
  --timeout <seconds>   Socket timeout in seconds (default: ${DEFAULT_TIMEOUT})
  --json                Print result as JSON
  --verbose             Enable verbose debug output
  -h, --help            Show this help message

Exit codes:
  0  Success (flag extracted)
  1  Generic failure
  2  Invalid arguments
  3  Connectivity failure
  4  Protocol parse failure
  5  Route rejected / flag not found
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
      --host)
        HOST="${2:-}"
        shift 2
        ;;
      --port)
        PORT="${2:-}"
        shift 2
        ;;
      --path)
        PATH_STR="${2:-}"
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
}

validate_input() {
  if ! [[ "${PORT}" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
    log_error "Invalid port: ${PORT}"
    exit 2
  fi
  if ! [[ "${PATH_STR}" =~ ^[LRFBUDQ]+$ ]]; then
    log_error "Path contains invalid characters. Allowed: L R F B U D Q"
    exit 2
  fi
}

main() {
  parse_args "$@"
  validate_input

  log_info "Target: ${HOST}:${PORT}"
  log_info "Replaying recovered route..."

  local result
  if ! result="$(python3 - "${HOST}" "${PORT}" "${TIMEOUT}" "${PATH_STR}" "${VERBOSE}" <<'PY'
import re
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])
timeout = float(sys.argv[3])
path = sys.argv[4]
verbose = sys.argv[5] == "1"

prompt = b"Direction (L/R/F/B/U/D/Q)? "

def die(code: int, msg: str) -> None:
    print(msg)
    raise SystemExit(code)

try:
    sock = socket.create_connection((host, port), timeout=timeout)
except OSError as exc:
    die(3, f"ERR_CONNECT:{exc}")

sock.settimeout(timeout)
banner = b""

try:
    while prompt not in banner:
        try:
            chunk = sock.recv(4096)
        except socket.timeout:
            die(4, "ERR_PARSE:Timed out waiting for movement prompt")
        except OSError as exc:
            die(3, f"ERR_CONNECT:{exc}")
        if not chunk:
            die(4, "ERR_PARSE:Connection closed before first prompt")
        banner += chunk

    if verbose:
        print(f"DBG_BANNER_LEN:{len(banner)}")

    payload = "\n".join(path) + "\n"
    try:
        sock.sendall(payload.encode())
    except OSError as exc:
        die(3, f"ERR_CONNECT:{exc}")

    output = b""
    while True:
        try:
            chunk = sock.recv(4096)
        except socket.timeout:
            break
        except OSError as exc:
            die(3, f"ERR_CONNECT:{exc}")
        if not chunk:
            break
        output += chunk

    text = output.decode("latin-1", "ignore")
    m = re.search(r"HTB\{[^}]+\}", text)
    if not m:
        die(5, "ERR_NOFLAG:Flag not found in remote response")

    print(f"OK_FLAG:{m.group(0)}")
finally:
    try:
        sock.close()
    except Exception:
        pass
PY
)"; then
    case "$?" in
      3) log_error "Could not connect to target."; exit 3 ;;
      4) log_error "Could not parse interaction prompts."; exit 4 ;;
      5) log_error "Route replay completed but no flag found."; exit 5 ;;
      *) log_error "Unexpected runtime failure."; exit 1 ;;
    esac
  fi

  log_debug "Solver output: ${result}"
  local flag
  flag="$(printf '%s\n' "${result}" | sed -n 's/^OK_FLAG://p' | tail -n 1)"
  if [[ -z "${flag}" ]]; then
    log_error "No flag extracted from solver output."
    exit 1
  fi

  if [[ "${JSON_OUTPUT}" -eq 1 ]]; then
    printf '{"target":"%s:%s","path_length":"%s","flag":"%s"}\n' "${HOST}" "${PORT}" "${#PATH_STR}" "${flag}"
  else
    log_ok "Flag extracted successfully."
    printf '%s\n' "${flag}"
  fi
}

main "$@"
