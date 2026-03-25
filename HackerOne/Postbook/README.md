# Postbook

## Overview

This directory contains the local materials and saved solve workflow for the `Postbook` challenge from `Hacker101 CTF / HackerOne`. This is a web challenge built around insecure session design. The application treats a client-controlled cookie as the user’s identity, and that cookie is derived from a predictable value instead of being a secure session token.

The result is full account impersonation with no need for password guessing or memory corruption. Once the attacker understands how the cookie is generated, admin access becomes trivial.

## Challenge Profile

- Challenge: `Postbook`
- Category: `Web`
- Collection: `HackerOne`
- Event or Platform: `Hacker101 CTF / HackerOne`
- Saved PoC: `postbook_poc.sh`

## Directory Contents

- `postbook_poc.sh`

## First Commands To Run

Read the saved PoC:

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/Postbook"
ls -lah
sed -n "1,220p" "postbook_poc.sh"
```

Run it:

```bash
chmod +x "postbook_poc.sh"
./postbook_poc.sh
```

## Core Vulnerability

The important discovery in this challenge is that the application’s `id` cookie is not a secure random session token. It is simply the MD5 hash of the numeric user ID.

That means if a user account has ID `4`, the cookie becomes:

```text
md5("4") = a87ff679a2f3e71d9181a67b7542122c
```

If the admin account is user ID `1`, then the attacker can compute:

```text
md5("1") = c4ca4238a0b923820dcc509a6f75849b
```

and set that cookie manually.

At that point, the application treats the attacker as the admin user.

## Why Hashing Does Not Help Here

This challenge is a perfect example of a common misconception: hashing a predictable value does not make it unpredictable. If the input space is tiny and guessable, the output is just as easy to enumerate.

The server is effectively trusting:

- a value chosen by the client
- derived from a tiny identifier space
- with no server-side integrity check

That is not session management. It is identity by user-supplied token.

## Manual Solve Workflow

The practical workflow is:

1. create or inspect a normal account
2. observe the `id` cookie assigned after login
3. recognize that it matches `md5(user_id)`
4. compute the cookie for the admin user ID
5. request an admin-only page while sending the forged cookie

The saved write-up notes that the admin home page was enough to reveal the flag.

If you want to reproduce the core idea manually in Python:

```bash
python3 - <<'PY'
import hashlib
print(hashlib.md5(b"1").hexdigest())
PY
```

That gives the forged admin cookie value.

## Why This Challenge Matters

This is a foundational web-security lesson. Authentication and authorization must be bound to trusted server-side state. A client must never be allowed to mint or reinterpret its own identity token unless that token is strongly protected, for example with:

- server-side session storage
- signed tokens
- high-entropy opaque session IDs
- proper validation and expiration controls

If the browser can forge the identity value, the application no longer controls who the user is.

## Reproduction Commands

Use this sequence for the fast path:

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/Postbook"
sed -n "1,220p" "postbook_poc.sh"
bash "postbook_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are studying broken session management and client-side trust failures. It is simple, but it captures one of the most important truths in web security: the server must decide identity, not the browser.
