# TunnelMadness

## Overview

This directory contains the local materials and manual walkthrough for the `TunnelMadness` challenge on Hack The Box. This is a reversing challenge built around a 3D maze embedded directly in the binary. The main work is recovering the maze layout, understanding the movement mapping, and then replaying the correct route against the live service to obtain the real flag.

The local binary is useful for analysis, but it is not the final source of truth for the flag. The solve has to be completed against the spawned target.

## Challenge Profile

- Challenge: `TunnelMadness`
- Category: `Reversing`
- Platform: `Hack The Box`

## Directory Contents

- `rev_tunnelmadness/`
- `rev_tunnelmadness.zip`
- `tunnelmadness_poc.sh`

## First Commands To Run

Start with the original challenge materials in this folder. The goal is to identify the bug or recovery path from the provided files, then follow the numbered walkthrough below to reach the flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/TunnelMadness"
ls -lah
unzip -l "rev_tunnelmadness.zip"
```

Useful first inspection commands:

```bash
file 'rev_tunnelmadness.zip'
strings -n 5 'rev_tunnelmadness.zip' | head -200
```

## Challenge Structure

The binary stores a full `20 x 20 x 20` maze in `.rodata`. Each maze cell is represented as a structured record containing:

- x coordinate
- y coordinate
- z coordinate
- cell type

The cell types are:

- `0` = start
- `1` = open path
- `2` = wall
- `3` = goal

So the real reversing task is not to brute force terminal interaction. It is to extract the maze model from the program and then solve it as a graph problem.

## Key Insight

The program’s movement letters are not self-explanatory until you inspect the logic. The mapping recovered from the binary is:

- `B` = x-
- `R` = x+
- `L` = y-
- `F` = y+
- `D` = z-
- `U` = z+

Once that mapping is known, the route can be expressed as a string of movement commands and replayed automatically.

## Why The Remote Service Matters

The local binary includes a fake `/flag.txt` string. That is a deliberate trap. It means static extraction alone is not enough to finish the challenge cleanly. You must solve the maze locally, then send the valid path to the live service to retrieve the real flag.

That is why the archived reference notes does not stop at path recovery. It also handles the final remote interaction.

## Manual Analysis Commands

If you want to inspect the binary yourself, these commands are a good starting point:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/TunnelMadness"
strings -n 5 rev_tunnelmadness/tunnel | head -200
objdump -d -Mintel rev_tunnelmadness/tunnel | less
readelf -x .rodata rev_tunnelmadness/tunnel | less
```

If you prefer a debugger or disassembler:

```bash
gdb -q rev_tunnelmadness/tunnel
radare2 -AA rev_tunnelmadness/tunnel
```

What you want to recover:

- where the maze array begins
- the size of each maze entry
- how the program labels walls versus open cells
- how the movement letters map to coordinate changes
- where the success state is checked

## Recovered Route

The shortest valid route recovered during solving is:

```text
UUURFURURRFRRFFUUFURRUFUFFRFUFUUUUFFRRUUUFURFDFFUFFRRRRRFRR
```

That route is the key artifact in this solve. The archived notes in this folder simply feed that recovered route to the live service at the correct prompt sequence.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/TunnelMadness"
ls -lah
```

## Study Notes

This challenge is a good exercise in combining reversing with algorithmic reasoning:

- extract structured data from a binary
- recover hidden semantic mappings
- solve the resulting maze as a search problem
- replay the final answer against a remote service

It is worth revisiting if you want practice turning embedded static data into a graph and then separating the local analysis phase from the live flag retrieval phase.
