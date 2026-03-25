# TunnelMadness

## Overview

This directory contains the local materials and saved solve workflow for the `TunnelMadness` challenge on Hack The Box. This is a reversing challenge built around a 3D maze embedded directly in the binary. The main work is recovering the maze layout, understanding the movement mapping, and then replaying the correct route against the live service to obtain the real flag.

The local binary is useful for analysis, but it is not the final source of truth for the flag. The solve has to be completed against the spawned target.

## Challenge Profile

- Challenge: `TunnelMadness`
- Category: `Reversing`
- Platform: `Hack The Box`
- Saved PoC: `tunnelmadness_poc.sh`

## Directory Contents

- `rev_tunnelmadness/`
- `rev_tunnelmadness.zip`
- `tunnelmadness_poc.sh`

## First Commands To Run

Begin by reviewing the archive and the extracted binary:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/TunnelMadness"
ls -lah
unzip -l "rev_tunnelmadness.zip"
file rev_tunnelmadness/tunnel
```

Read the solve script comments:

```bash
sed -n "1,220p" "tunnelmadness_poc.sh"
```

Run the saved route against the service:

```bash
chmod +x "tunnelmadness_poc.sh"
./tunnelmadness_poc.sh
```

To target a new spawned instance:

```bash
./tunnelmadness_poc.sh <HOST> <PORT>
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

That is why the saved PoC does not stop at path recovery. It also handles the final remote interaction.

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

That route is the key artifact in this solve. The PoC simply feeds it to the live service at the correct prompt sequence.

## Reproduction Commands

Use this sequence for the shortest clean reproduction:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/TunnelMadness"
unzip -l "rev_tunnelmadness.zip"
sed -n "1,220p" "tunnelmadness_poc.sh"
bash "tunnelmadness_poc.sh"
```

## Study Notes

This challenge is a good exercise in combining reversing with algorithmic reasoning:

- extract structured data from a binary
- recover hidden semantic mappings
- solve the resulting maze as a search problem
- replay the final answer against a remote service

It is worth revisiting if you want practice turning embedded static data into a graph and then separating the local analysis phase from the live flag retrieval phase.
