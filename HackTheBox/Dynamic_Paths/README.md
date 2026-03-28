# Dynamic Paths

## Overview

This directory contains the local materials and manual walkthrough for the `Dynamic Paths` challenge on Hack The Box. This is an algorithms challenge where the service repeatedly sends weighted grids and expects the minimum path cost from the top-left corner to the bottom-right corner.

The challenge is a clean example of dynamic programming. The main difficulty is not the math itself, but recognizing the pattern quickly and implementing it in a way that can handle a stream of many rounds without timing out.

## Challenge Profile

- Challenge: `Dynamic Paths`
- Category: `Coding / Algorithms`
- Platform: `Hack The Box`

## Directory Contents

- `dynamic_paths_poc.sh`

## First Commands To Run

This folder does not include original challenge files. Follow the walkthrough the same way you would read a public writeup: understand the target behavior first, then reproduce each manual step against a fresh instance until the flag is visible.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Dynamic_Paths"
ls -lah
printf 'Follow the manual walkthrough below against the live service.\n'
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Problem Model

For each round, the service gives a grid of positive integers. You start at the top-left cell and must reach the bottom-right cell using only:

- right moves
- down moves

The goal is to minimize the total sum of the cells visited.

This is the standard minimum-path-sum dynamic programming problem.

## Why Dynamic Programming Fits

At any cell `(r, c)`, the cheapest way to arrive there can only come from:

- the cell directly above `(r-1, c)`
- the cell directly to the left `(r, c-1)`

So the recurrence is:

```text
cost[r][c] = min(cost[r-1][c], cost[r][c-1]) + grid[r][c]
```

The script uses a one-dimensional DP array to keep memory small:

```text
dp[c] = minimum cost to reach column c in the current row
```

And the update becomes:

```text
dp[c] = min(dp[c], dp[c - 1]) + grid[r][c]
```

That is enough to solve each grid efficiently while the service continues sending new rounds.

## Why The Saved archived notes Is Structured The Way It Is

The remote service does not send only one puzzle. It sends many, and it expects answers quickly. The script therefore handles three jobs:

1. keep the TCP connection open
2. parse each incoming grid cleanly
3. compute and return the answer immediately

That is why the archived reference notes is socket-driven rather than just a standalone local algorithm demo.

## Manual Testing Idea

If you want to confirm the algorithm on a small example before interacting with the service, you can test this locally in Python:

```bash
python3 - <<'PY'
grid = [
    [1, 3, 1],
    [1, 5, 1],
    [4, 2, 1],
]

rows = len(grid)
cols = len(grid[0])
dp = [0] * cols

for r in range(rows):
    for c in range(cols):
        val = grid[r][c]
        if r == 0 and c == 0:
            dp[c] = val
        elif r == 0:
            dp[c] = dp[c - 1] + val
        elif c == 0:
            dp[c] = dp[c] + val
        else:
            dp[c] = min(dp[c], dp[c - 1]) + val

print(dp[-1])
PY
```

That should print the minimum path sum for the sample grid.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Dynamic_Paths"
ls -lah
```

## Final Flag

Following the manual path in this README leads to: `HTB{b3h3M07H_5h0uld_H4v3_57ud13D_dYM4m1C_pr09r4mm1n9_70_C47ch_y0u_f25c7d6602463cccd4db4227827c9436}`

## Study Notes

This challenge is worth revisiting if you are practicing dynamic programming under time pressure. It is especially useful as a pattern-recognition exercise: once you identify the problem class, the implementation is short, reliable, and fast enough to solve all rounds automatically.
