# NotADemocraticElection

## Overview

This directory contains the local materials and manual walkthrough for the `NotADemocraticElection` challenge on Hack The Box. This is a blockchain challenge where the smart contract looks straightforward at first, but the vote-accounting logic is broken in two separate ways.

The critical bug is an `abi.encodePacked` collision on two dynamic strings. A second issue then makes the attack even stronger by allowing the same voter weight to be reused repeatedly.

## Challenge Profile

- Challenge: `NotADemocraticElection`
- Category: `Blockchain`
- Platform: `Hack The Box`

## Directory Contents

- `blockchain_notademocraticelection/`
- `blockchain_notademocraticelection.zip`
- `not_a_democratic_election_poc.sh`

## First Commands To Run

Start with the original challenge materials in this folder. The goal is to identify the bug or recovery path from the provided files, then follow the numbered walkthrough below to reach the flag manually.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/NotADemocraticElection"
ls -lah
unzip -l "blockchain_notademocraticelection.zip"
```

Useful first inspection commands:

```bash
file 'blockchain_notademocraticelection.zip'
strings -n 5 'blockchain_notademocraticelection.zip' | head -200
```

## Core Vulnerability

The contract derives a voter identity using:

```solidity
abi.encodePacked(_name, _surname)
```

That is unsafe when multiple dynamic strings are concatenated without separators. Different inputs can produce the same packed byte sequence.

In this challenge:

- the setup already registers `("Satoshi", "Nakamoto")`
- the attacker registers `("SatoshiN", "akamoto")`

Both become the exact same concatenated string:

```text
SatoshiNakamoto
```

That means the attacker can collide with the stored voter identity and inherit the collateral associated with the original entry.

## Why The Attack Works So Well

The setup funds the legitimate voter record with enough value to matter in the election. Once the attacker registers a colliding identity under their own address, the contract treats that attacker-controlled entry as if it were the same logical voter.

That would already be a serious bug. The challenge then adds a second flaw: the voting logic does not properly mark the voter as spent after a vote is cast.

So the same weight can be used repeatedly.

The exploit therefore becomes:

1. Retrieve the launcher information.
2. Extract the player private key, player address, setup contract, and target contract.
3. Register the colliding voter pair.
4. Vote for `CIM` repeatedly with the inherited weight.
5. Check `isSolved()`.
6. Ask the launcher for the flag.

## Manual Review Commands

These commands are helpful if you want to reason through the bug directly in the contract source:

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/NotADemocraticElection"
rg -n "encodePacked|vote|collateral|isSolved|winner" blockchain_notademocraticelection
sed -n '1,260p' blockchain_notademocraticelection/NotADemocraticElection.sol
```

When reading the contract, focus on:

- how voter identity is computed
- where deposited collateral is stored
- whether voting consumes or locks that collateral
- whether repeated calls from the same effective voter are prevented

## Practical Execution Model

The archived notes in this folder talk to both of the following services:

- the launcher service that exposes the challenge metadata
- the JSON-RPC endpoint that accepts transactions

The script:

- requests the challenge information from the launcher
- signs transactions with the supplied private key
- registers the colliding voter pair
- votes ten times for `CIM`
- checks `isSolved()`
- requests the flag from the launcher

That makes the solve easy to reproduce without rebuilding the exploit logic from scratch.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackTheBox/NotADemocraticElection"
ls -lah
```

## Study Notes

This challenge is a strong reminder that blockchain bugs are often ordinary software bugs expressed in smart-contract form. Here the main problem is not cryptographic at all. It is ambiguous data encoding combined with missing state enforcement.

It is worth revisiting if you want practice with:

- `abi.encodePacked` collision risks
- state-accounting flaws in Solidity
- scripting end-to-end interactions with a challenge launcher and RPC node
