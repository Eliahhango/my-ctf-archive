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

This folder does not include original challenge files. Start by reading the challenge description and the manual walkthrough below, then connect to a fresh challenge instance and reproduce the steps one by one.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/Dynamic_Paths"
ls -lah
printf 'Follow the manual walkthrough below against the live service.\n'
```

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

## Study Notes

This challenge is worth revisiting if you are practicing dynamic programming under time pressure. It is especially useful as a pattern-recognition exercise: once you identify the problem class, the implementation is short, reliable, and fast enough to solve all rounds automatically.
