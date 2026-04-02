#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - Stop Drop and Roll
# Type: Deterministic interactive protocol automation
# Transport: Raw TCP
#
# This script is intended for authorized CTF infrastructure only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEOUT=8
readonly DEFAULT_ROUND_LIMIT=2000

HOST=""
PORT=""
TIMEOUT="${DEFAULT_TIMEOUT}"
ROUND_LIMIT="${DEFAULT_ROUND_LIMIT}"
JSON_OUTPUT=0
VERBOSE=0

usage() {
  cat <<EOF
Usage:
  ${SCRIPT_NAME} <host> <port>
  ${SCRIPT_NAME} --host <host> --port <port> [options]

Options:
  --host <host>            Target host or IP address
  --port <port>            Target TCP port
  --timeout <seconds>      Socket timeout in seconds (default: ${DEFAULT_TIMEOUT})
  --round-limit <n>        Maximum rounds to solve before failing (default: ${DEFAULT_ROUND_LIMIT})
  --json                   Print result as JSON
  --verbose                Enable verbose debug output
  -h, --help               Show this help message

Exit codes:
  0  Success (flag extracted)
  1  Generic failure
  2  Invalid arguments
  3  Connectivity failure
  4  Protocol parse failure
  5  Round limit reached before receiving flag
  6  Connection closed before receiving flag
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
      --timeout)
        TIMEOUT="${2:-}"
        shift 2
        ;;
      --round-limit)
        ROUND_LIMIT="${2:-}"
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
  if ! [[ "${ROUND_LIMIT}" =~ ^[0-9]+$ ]] || (( ROUND_LIMIT < 1 )); then
    log_error "round-limit must be a positive integer."
    exit 2
  fi
}

main() {
  parse_args "$@"
  validate_input

  log_info "Target: ${HOST}:${PORT}"
  log_info "Automating hazard-to-action rounds..."

  local result
  if ! result="$(python3 - "${HOST}" "${PORT}" "${TIMEOUT}" "${ROUND_LIMIT}" "${VERBOSE}" <<'PY'
import re
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])
timeout = float(sys.argv[3])
round_limit = int(sys.argv[4])
verbose = sys.argv[5] == "1"

mapping = {"GORGE": "STOP", "PHREAK": "DROP", "FIRE": "ROLL"}
prompt = "What do you do? "
hazard_line_re = re.compile(r"(?:GORGE|PHREAK|FIRE)(?:,\s*(?:GORGE|PHREAK|FIRE))*$")

def die(code: int, msg: str) -> None:
    print(msg)
    raise SystemExit(code)

try:
    sock = socket.create_connection((host, port), timeout=timeout)
except OSError as exc:
    die(3, f"ERR_CONNECT:{exc}")

sock.settimeout(timeout)
rounds = 0
buffer = ""

try:
    # Read intro until ready prompt.
    while "(y/n)" not in buffer:
        try:
            chunk = sock.recv(4096)
        except socket.timeout:
            die(4, "ERR_PARSE:Timed out waiting for '(y/n)' prompt")
        except OSError as exc:
            die(6, f"ERR_EOF:Socket read failed before start prompt: {exc}")
        if not chunk:
            die(6, "ERR_EOF:Connection closed before start prompt")
        buffer += chunk.decode("latin-1", "ignore")

    try:
        sock.sendall(b"y\n")
    except OSError as exc:
        die(6, f"ERR_EOF:Socket write failed while starting game: {exc}")
    buffer = ""

    while True:
        # Pull data until we can either answer or extract the flag.
        while "HTB{" not in buffer and prompt not in buffer:
            try:
                chunk = sock.recv(4096)
            except socket.timeout:
                die(4, "ERR_PARSE:Timed out waiting for round prompt or flag")
            except OSError as exc:
                die(6, f"ERR_EOF:Socket read failed mid-game: {exc}")
            if not chunk:
                die(6, "ERR_EOF:Connection closed before flag")
            buffer += chunk.decode("latin-1", "ignore")

        mflag = re.search(r"HTB\{[^}]+\}", buffer)
        if mflag:
            print(f"OK_FLAG:{mflag.group(0)}")
            print(f"OK_ROUNDS:{rounds}")
            raise SystemExit(0)

        while prompt in buffer:
            prefix, remainder = buffer.split(prompt, 1)
            lines = [ln.strip() for ln in prefix.splitlines() if ln.strip()]

            scenario = None
            for ln in reversed(lines):
                if hazard_line_re.fullmatch(ln):
                    scenario = ln
                    break

            if scenario is None:
                # Need more data to find a valid scenario line.
                buffer = prefix + prompt + remainder
                break

            hazards = [h.strip() for h in scenario.split(",")]
            try:
                answer = "-".join(mapping[h] for h in hazards)
            except KeyError as exc:
                die(4, f"ERR_PARSE:Unexpected hazard token: {exc.args[0]}")

            try:
                sock.sendall((answer + "\n").encode())
            except OSError as exc:
                die(6, f"ERR_EOF:Socket write failed mid-game: {exc}")
            rounds += 1

            if verbose:
                print(f"DBG_ROUND:{rounds}:{scenario}->{answer}")

            if rounds >= round_limit:
                die(5, "ERR_ROUND_LIMIT:Reached round limit before flag")

            buffer = remainder
finally:
    try:
        sock.close()
    except Exception:
        pass
PY
)"; then
    case "$?" in
      3) log_error "Could not connect to target."; exit 3 ;;
      4) log_error "Protocol parsing failed."; exit 4 ;;
      5) log_error "Round limit reached before flag."; exit 5 ;;
      6) log_error "Connection closed before receiving flag."; exit 6 ;;
      *) log_error "Unexpected runtime failure."; exit 1 ;;
    esac
  fi

  log_debug "Solver output: ${result}"
  local flag rounds
  flag="$(printf '%s\n' "${result}" | sed -n 's/^OK_FLAG://p' | tail -n 1)"
  rounds="$(printf '%s\n' "${result}" | sed -n 's/^OK_ROUNDS://p' | tail -n 1)"

  if [[ -z "${flag}" ]]; then
    log_error "No flag extracted from solver output."
    exit 1
  fi

  if [[ "${JSON_OUTPUT}" -eq 1 ]]; then
    printf '{"target":"%s:%s","rounds":"%s","flag":"%s"}\n' "${HOST}" "${PORT}" "${rounds:-unknown}" "${flag}"
  else
    log_ok "Flag extracted successfully in ${rounds:-unknown} rounds."
    printf '%s\n' "${flag}"
  fi
}

main "$@"
