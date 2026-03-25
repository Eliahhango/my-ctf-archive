# Failure Failure

## Overview

This directory contains the local materials and saved solve workflow for the `Failure Failure` challenge from `picoCTF 2026`. This is a web and infrastructure challenge built around the interaction between application behavior and load-balancer health checks. The flag is not hidden behind a memory corruption bug or a forgotten route. It becomes reachable only after the attacker forces the primary backend to look unhealthy enough that HAProxy fails over to the backup system.

This is a useful challenge because it teaches a real operational security lesson: availability logic can create an attack surface when backup systems behave differently from primary systems.

## Challenge Profile

- Challenge: `Failure Failure`
- Category: `General Skills`
- Collection: `picoCTF`
- Event or Platform: `picoCTF 2026`
- Difficulty: `Medium`
- Author: `DARKRAICG492`
- Saved PoC: `failure_failure_poc.sh`

## Directory Contents

- `app.py`
- `failure_failure_poc.sh`
- `haproxy.cfg`

## First Commands To Run

Start by reading the application and HAProxy configuration side by side:

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Failure_Failure"
ls -lah
sed -n '1,220p' app.py
sed -n '1,260p' haproxy.cfg
```

Read the saved PoC next:

```bash
sed -n "1,220p" "failure_failure_poc.sh"
```

Run it:

```bash
chmod +x "failure_failure_poc.sh"
./failure_failure_poc.sh
```

## Core Vulnerability

The backend Flask application uses a global rate limiter. Once the request rate is exceeded, it returns `503 Service Unavailable` instead of a normal rate-limit code such as `429`.

That is the critical mistake.

HAProxy is configured to health-check the primary server by requesting `/` and expecting a `200` response. After enough failed checks, the primary is marked down and traffic is automatically sent to the backup server.

So the challenge becomes:

1. generate enough traffic to push the global limiter over its threshold
2. cause the primary to start returning `503`
3. let HAProxy observe those failures
4. wait for failover to the backup
5. request `/` again and collect the flag

## Why The Backup Matters

The source code makes it clear that the backup node behaves differently from the primary node. On the primary, the home route does not reveal the flag. On the backup, it does.

That means the attack is not “find a hidden flag endpoint.” The attack is “force the infrastructure to route us to the node that exposes the secret.”

This is a very realistic concept in production systems:

- primary and backup systems drift apart
- emergency or maintenance modes expose extra information
- health checks become a lever for steering traffic

## Manual Analysis Workflow

First inspect the Flask application:

```bash
sed -n '1,220p' app.py
```

Things to notice:

- the rate-limit bucket is global rather than per user
- the limiter threshold is fixed
- exceeding the limit leads to a `503`
- the home route returns different output depending on backup state

Then inspect HAProxy:

```bash
sed -n '1,260p' haproxy.cfg
```

What matters there:

- `option httpchk GET /`
- `http-check expect status 200`
- failover after repeated failed checks
- a designated backup server

Once you understand both files together, the solve path becomes obvious.

## Triggering Failover

The saved PoC floods the service with enough concurrent requests to exceed the limiter and then polls until the flag appears. That is the practical way to reproduce the behavior.

A manual version of the same idea would be:

```bash
python3 - <<'PY'
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed

base = 'http://mysterious-sea.picoctf.net:50441/'

def hit(_):
    try:
        return requests.get(base, timeout=5).status_code
    except Exception:
        return 'ERR'

with ThreadPoolExecutor(max_workers=40) as ex:
    list(as_completed(ex.submit(hit, i) for i in range(360)))
PY
```

Then poll the homepage:

```bash
curl -s "http://mysterious-sea.picoctf.net:50441/"
```

Once HAProxy has marked the primary down, the backup response includes the flag.

## Why This Challenge Is Valuable

This is a good challenge because it pushes you to think beyond “the application” and include the load balancer, health checks, and failover design in your mental model. Those operational layers often decide what is reachable in the first place.

The deeper lesson is simple: security-relevant behavior must stay consistent across primary and backup systems, and health-check failure codes should be designed carefully.

## Reproduction Commands

Use this sequence for the fastest path:

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Failure_Failure"
sed -n '1,220p' app.py
sed -n '1,260p' haproxy.cfg
sed -n "1,220p" "failure_failure_poc.sh"
bash "failure_failure_poc.sh"
```

## Study Notes

This folder is especially useful if you are studying the overlap between web application security and operational infrastructure. It is a strong reminder that load balancers, failover rules, and health checks are part of the security model whether the developers intend them to be or not.
