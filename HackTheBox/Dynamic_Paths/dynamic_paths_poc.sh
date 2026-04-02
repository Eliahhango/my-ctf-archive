#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - Dynamic Paths
# Type: Repeated minimum path sum (dynamic programming) over raw TCP protocol
#
# This script is intended for authorized CTF infrastructure only.
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEOUT=10
readonly DEFAULT_ROUND_LIMIT=1000

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
  log_info "Solving minimum-path grids with dynamic programming..."

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

prompt = "\n> "

def die(code: int, msg: str) -> None:
    print(msg)
    raise SystemExit(code)

def min_path_sum(rows: int, cols: int, vals: list[int]) -> int:
    dp = [0] * cols
    idx = 0
    for r in range(rows):
        for c in range(cols):
            v = vals[idx]
            idx += 1
            if r == 0 and c == 0:
                dp[c] = v
            elif r == 0:
                dp[c] = dp[c - 1] + v
            elif c == 0:
                dp[c] = dp[c] + v
            else:
                dp[c] = min(dp[c], dp[c - 1]) + v
    return dp[-1]

def parse_round(prefix: str):
    # Find the last valid "rows cols" declaration and gather rows*cols integers after it.
    lines = [ln.strip() for ln in prefix.splitlines() if ln.strip()]
    dims = None
    values = None

    for i, ln in enumerate(lines):
        parts = ln.split()
        if len(parts) != 2 or not all(p.isdigit() for p in parts):
            continue

        r, c = map(int, parts)
        need = r * c
        if need <= 0:
            continue

        collected = []
        for follow in lines[i + 1:]:
            if re.fullmatch(r"[0-9 ]+", follow):
                collected.extend(int(x) for x in follow.split() if x)
                if len(collected) >= need:
                    break
            elif collected:
                # Stop if we started collecting and reached a non-numeric line.
                break

        if len(collected) >= need:
            dims = (r, c)
            values = collected[:need]

    if dims is None or values is None:
        return None
    return dims[0], dims[1], values

try:
    sock = socket.create_connection((host, port), timeout=timeout)
except OSError as exc:
    die(3, f"ERR_CONNECT:{exc}")

sock.settimeout(timeout)
buffer = ""
solved = 0

try:
    while True:
        while "HTB{" not in buffer and prompt not in buffer:
            try:
                chunk = sock.recv(8192)
            except socket.timeout:
                die(4, "ERR_PARSE:Timed out waiting for puzzle prompt or flag")
            except OSError as exc:
                die(6, f"ERR_EOF:Socket read failed: {exc}")
            if not chunk:
                die(6, "ERR_EOF:Connection closed before flag")
            buffer += chunk.decode("latin-1", "ignore")

        mflag = re.search(r"HTB\{[^}]+\}", buffer)
        if mflag:
            print(f"OK_FLAG:{mflag.group(0)}")
            print(f"OK_ROUNDS:{solved}")
            raise SystemExit(0)

        while prompt in buffer:
            prefix, remainder = buffer.split(prompt, 1)
            parsed = parse_round(prefix)
            if parsed is None:
                # Not enough data to parse this round yet.
                buffer = prefix + prompt + remainder
                break

            rows, cols, values = parsed
            answer = min_path_sum(rows, cols, values)

            try:
                sock.sendall(f"{answer}\n".encode())
            except OSError as exc:
                die(6, f"ERR_EOF:Socket write failed: {exc}")

            solved += 1
            if verbose:
                print(f"DBG_ROUND:{solved}:{rows}x{cols}->{answer}")

            if solved >= round_limit:
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
