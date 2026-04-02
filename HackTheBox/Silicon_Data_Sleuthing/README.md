# Silicon Data Sleuthing (Hack The Box) - Professional PoC Writeup

## Challenge Profile

| Field | Value |
|---|---|
| Challenge | Silicon Data Sleuthing |
| Category | Forensics |
| Difficulty | Easy |
| Primary dropped file | `forensics_silicon_data_sleuthing.zip` |
| Existing local PoC before this update | Present |
| Core challenge type | Firmware artifact extraction + fixed remote questionnaire |

## Scope And Ethics

This material is for authorized CTF infrastructure only. Do not run this PoC
against systems you do not own or have explicit permission to test.

## Technical Summary

The service is a guided validation challenge: it asks a fixed sequence of
OpenWrt firmware questions, and returns the flag only if every answer is exact.

The local artifact (`chal_router_dump.bin`) is a router firmware dump where:
1. OpenWrt release data is visible in extracted filesystem metadata.
2. Kernel version is visible in `uImage` metadata.
3. The remaining challenge answers are validated as strict expected strings.

The PoC automates this flow by waiting for each prompt (`> `), sending the
known answer in order, then extracting `HTB{...}` from the final response.

## Required Answer Set

1. `23.05.0`
2. `5.15.134`
3. `root:$1$YfuRJudo$cXCiIJXn9fWLIt8WY2Okp1:19804:0:99999:7:::`
4. `yohZ5ah`
5. `ae-h+i$i^Ngohroorie!bieng6kee7oh`
6. `VLT-AP01`
7. `french-halves-vehicular-favorable`
8. `1778,2289,8088`

## Manual Verification Steps

1. Check dropped archive contents:

```bash
cd "/home/eliah/Desktop/CTF"
unzip -l forensics_silicon_data_sleuthing.zip
```

2. Verify firmware characteristics:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Silicon_Data_Sleuthing"
file challenge.bin
binwalk challenge.bin
```

You should see:
- OpenWrt kernel image metadata containing `Linux-5.15.134`.
- SquashFS root filesystem and additional flash sections.

3. Extract filesystem and confirm OpenWrt release string:

```bash
binwalk -eM challenge.bin
sed -n '1,40p' _extract/_challenge.bin.extracted/squashfs-root/etc/openwrt_release
```

Expected release value includes `DISTRIB_RELEASE='23.05.0'`.

4. Solve remotely by answering prompts in order (manual or PoC), then verify
output contains `HTB{...}`.

## Automated PoC

Script:
`silicon_data_sleuthing_poc.sh`

### Usage

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Silicon_Data_Sleuthing"
chmod +x silicon_data_sleuthing_poc.sh
./silicon_data_sleuthing_poc.sh <host> <port>
```

### Common examples

```bash
./silicon_data_sleuthing_poc.sh 154.57.164.80 31783
./silicon_data_sleuthing_poc.sh --host 154.57.164.80 --port 31783 --verbose
./silicon_data_sleuthing_poc.sh --host 154.57.164.80 --port 31783 --json
```

## Options

- `--host <host>`: target host or IP.
- `--port <port>`: target TCP port.
- `--timeout <seconds>`: socket timeout, default `10`.
- `--json`: machine-readable JSON output.
- `--verbose`: print debug output.
- `-h`, `--help`: show usage help.

## Exit Codes

- `0`: exploit succeeded and flag extracted.
- `2`: invalid CLI arguments.
- `3`: connectivity/protocol failure.
- `4`: answers submitted but flag not found.

## Why The PoC Works

- The service uses deterministic prompt order with strict string matching.
- No branching logic is required once the correct answer list is known.
- Automating prompt synchronization prevents input timing mistakes.
- Flag extraction is a simple `HTB{...}` regex from final server output.

## Defensive Guidance

- Never store sensitive credentials or hashes in recoverable firmware images.
- Encrypt and protect configuration backups before firmware distribution.
- Validate challenge services with dynamic per-instance secrets where possible.
- Add stricter transport controls and attempt limits on verification endpoints.

## Result Note

Flag values are instance-specific. The format remains `HTB{...}`.

## Final Flag

Target instance: `154.57.164.80:31783`  
Solved on: `2026-04-02`  
Flag: `HTB{Y0u'v3_m4st3r3d_0p3nWRT_d4t4_3xtr4ct10n!!_75e2f44c2c7e3087aacbcb561878b48f}`
