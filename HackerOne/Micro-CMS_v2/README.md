# Micro-CMS v2

## Overview

This directory contains the local materials and saved solve workflow for the `Micro-CMS v2` challenge from `Hacker101 / HackerOne CTF`. This level is a strong follow-up to the original Micro-CMS because it shows a very realistic pattern: some obvious bugs were fixed, but the application still contains several broken trust boundaries.

The saved PoC covers three flags built around SQL injection, missing authorization on one HTTP method, and secret leakage through the login flow itself.

## Challenge Profile

- Challenge: `Micro-CMS v2`
- Category: `Web`
- Collection: `HackerOne`
- Event or Platform: `Hacker101 / HackerOne CTF`
- Saved PoC: `micro_cms_v2_poc.sh`

## Directory Contents

- `micro_cms_v2_poc.sh`

## First Commands To Run

Start by reading the saved notes:

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/Micro-CMS_v2"
ls -lah
sed -n "1,260p" "micro_cms_v2_poc.sh"
```

Run the PoC:

```bash
chmod +x "micro_cms_v2_poc.sh"
./micro_cms_v2_poc.sh
```

## Why This Level Is Educational

This challenge reflects a very common real-world situation: developers patch the last obvious issue, but only along one path. The result is an application where:

- one route is protected
- a sibling route is still exposed
- one query path is hardened
- another query path still leaks data

That makes `v2` a useful case study in incomplete fixes.

## Flag 0: SQL Injection Login Bypass

The login form is vulnerable to SQL injection in the username field. The saved payload uses a `UNION SELECT` trick to force the backend to compare against a password value controlled by the attacker.

That creates an artificial admin session and exposes an otherwise hidden private page.

This is a good reminder that even when the visible feature is “login,” the real bug may simply be unsafely constructed SQL.

## Flag 1: POST Authorization Bypass

One of the strongest lessons in this level is the mismatch between HTTP methods:

- `GET /page/edit/2` appears protected
- `POST /page/edit/2` still succeeds without authentication

That is a classic access-control failure. The front door is locked, but the action handler behind it still trusts the caller.

This kind of bug appears often in real applications when developers check authorization in the page-rendering route but forget to enforce it in the state-changing route.

## Flag 2: Real Credential Extraction Through SQLi

The challenge goes beyond the artificial login bypass by hinting that the real admin credentials still matter. The same SQL injection primitive can be adapted into a blind extraction process that reveals the actual username and password stored in the admins table.

Once the real credentials are known, logging in normally returns the third flag.

This is a useful distinction:

- authentication bypass may get you access
- data extraction may still reveal the true underlying secret

Both matter, and both are consequences of the same root vulnerability.

## Why This Challenge Matters

This level is a very realistic example of patch-incomplete security:

- one route fixed, another missed
- one login behavior hardened, underlying query still injectable
- one trust boundary enforced, adjacent one forgotten

That is why reviewing applications by feature rather than by bug class can be dangerous. If the whole class of issue is not removed, related paths often remain exploitable.

## Reproduction Commands

Use this sequence for the fastest path:

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/Micro-CMS_v2"
sed -n "1,260p" "micro_cms_v2_poc.sh"
bash "micro_cms_v2_poc.sh"
```

## Study Notes

This is one of the better HackerOne folders for studying how several app-logic failures can survive an attempted security revision. It is worth revisiting if you want practice recognizing incomplete remediations and checking all related request paths rather than trusting the protected-looking one.
