# Its Oops PM

## Overview

This directory contains the local materials and saved solve workflow for the `Its Oops PM` challenge on Hack The Box CTF Try Out. This README is written as a practical walkthrough so someone can open the folder, inspect the challenge files, understand the intended weakness, and reproduce the solve with commands that are easy to copy and run.

## Challenge Profile

- Challenge: `It's Oops PM`
- Category: `Hardware`
- Platform: `Hack The Box CTF Try Out`
- Saved PoC: `its_oops_pm_poc.sh`

## Directory Contents

- `hardware_its_oops_pm/`
- `hardware_its_oops_pm.zip`
- `its_oops_pm_poc.sh`

## First Commands To Run

Begin with a short inventory so you can see the original challenge archive, any extracted directories, and the solve script saved in this folder.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Its_Oops_PM"
ls -lah
```

If you want to verify what was originally provided by Hack The Box, inspect the archive contents before extracting or re-extracting them.

```bash
unzip -l "hardware_its_oops_pm.zip"
```

Read the top of the PoC first. The comments there summarize the exact idea used during the solve and usually explain the bug, leak, algorithm, or reversing trick directly.

```bash
sed -n "1,220p" "its_oops_pm_poc.sh"
```

Run the PoC after reviewing the notes.

```bash
chmod +x "its_oops_pm_poc.sh"
./its_oops_pm_poc.sh
```

If the script targets a spawned remote service, you can usually point it at a fresh instance by supplying a host and port.

```bash
./its_oops_pm_poc.sh <HOST> <PORT>
```

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

## Reproduction Commands

Use the following command sequence if you want a short and reliable path from opening the folder to reproducing the saved solve.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Its_Oops_PM"
unzip -l "hardware_its_oops_pm.zip"
sed -n "1,220p" "its_oops_pm_poc.sh"
bash "its_oops_pm_poc.sh"
```

## Study Notes

This challenge is worth revisiting if you are practicing `Hardware` problems. The saved PoC is meant to be the fast path, but the better learning path is to inspect the provided files yourself first, confirm the weakness manually, and then compare your reasoning with the script comments and implementation.
