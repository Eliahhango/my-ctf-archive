# Its Oops PM

## Overview

This directory contains the local materials and manual walkthrough for the `Its Oops PM` challenge on Hack The Box CTF Try Out. This README is written as a practical walkthrough so someone can open the folder, inspect the challenge files, understand the intended weakness, and reproduce the solve with commands that are easy to copy and run.

## Challenge Profile

- Challenge: `It's Oops PM`
- Category: `Hardware`
- Platform: `Hack The Box CTF Try Out`

## Directory Contents

- `hardware_its_oops_pm/`
- `hardware_its_oops_pm.zip`
- `its_oops_pm_poc.sh`

## First Commands To Run

Start with the original challenge materials in this folder. Treat this like a proper writeup: inspect what was provided, identify the relevant clue or weakness, verify it with the commands below, and continue until you can see or submit the final flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Its_Oops_PM"
ls -lah
unzip -l "hardware_its_oops_pm.zip"
```

Useful first inspection commands:

```bash
file 'hardware_its_oops_pm.zip'
strings -n 5 'hardware_its_oops_pm.zip' | head -200
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Walkthrough

Challenge: It's Oops PM
Category: Hardware
Platform: Hack The Box CTF Try Out

### Files provided

- encryption.vhdl
- backdoor.vhdl
- key.vhdl
- tpm.vhdl
- schematic.png

Core idea:
This is a hardware backdoor challenge. Instead of "breaking" the encryption,
we read the HDL and notice a hidden trigger value that makes the chip leak the
secret key directly.

### What the VHDL tells us

1. key.vhdl hardcodes the key:
0110001111100001

2. encryption.vhdl mostly does:
E(i) = D(i) XOR K(i)
except bits 0, 6, and 13, which are forced to NOT K(bit).

3. backdoor.vhdl defines a special 16-bit input pattern:
1111111111101001

4. tpm.vhdl wires everything together:
- If Data equals the backdoor pattern, Output becomes the raw key
- Otherwise Output becomes the encrypted value

So the intended attack is:
- Send the exact backdoor pattern to the live service
- The service reveals the secret key instead of a normal encrypted output
- The service then prints the flag

### Real-world lesson

Secure hardware can fail completely when a hidden debug/backdoor path is left
in production logic. Strong encryption does not matter if a privileged bypass
can dump the key directly.

### Manual reproduction

1. Connect:
nc 154.57.164.72 31978

2. Send the backdoor trigger:
1111111111101001

3. Observe:
Output: 0110001111100001
You triggered the backdoor here is the flag: ...

Flag obtained on this instance:
HTB{4_7yp1c41_53cu23_TPM_ch1p}

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Its_Oops_PM"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `HTB{4_7yp1c41_53cu23_TPM_ch1p}`

## Study Notes

This challenge is worth revisiting if you are practicing `Hardware` problems. The better learning path is to inspect the provided files yourself first, confirm the weakness manually, and then compare your reasoning with the archived notes only if needed.
