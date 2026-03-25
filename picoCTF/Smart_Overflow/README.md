# Smart Overflow

## Overview

This directory contains the local materials and saved solve workflow for the `Smart_Overflow` challenge from `picoCTF 2026`. The goal of this README is to make the folder immediately useful to someone reviewing the archive later: what the challenge was about, what files matter, how the solve works at a high level, and which commands to run first.

## Challenge Profile

- Challenge: `Smart_Overflow`
- Category: `Blockchain`
- Collection: `picoCTF`
- Event or Platform: `picoCTF 2026`
- Difficulty: `Medium`
- Author: `OB`
- Saved PoC: `smart_overflow_poc.sh`

## Directory Contents

- `IntOverflowBank.sol`
- `package-lock.json`
- `package.json`
- `smart_overflow_poc.sh`

## First Commands To Run

Start by listing the directory and reading the saved proof-of-concept script. In this archive, the PoC comments are treated as the primary solve notes and usually contain the most important reasoning.

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Smart_Overflow"
ls -lah
sed -n "1,220p" "smart_overflow_poc.sh"
```

If you want to execute the saved solve directly:

```bash
chmod +x "smart_overflow_poc.sh"
./smart_overflow_poc.sh
```

Many of these saved scripts also accept a target host and port so they can be reused against a fresh instance:

```bash
./smart_overflow_poc.sh <HOST> <PORT>
```

## Walkthrough

Challenge Name: Smart_Overflow
Category: Blockchain
Difficulty: Medium
Event: picoCTF 2026
Author: OB

### Description

"The contract tracks balances using uint256 math. It should be impossible to
get the flag... Contract: here"

### Given information from the challenge

Web page: http://mysterious-sea.picoctf.net:52388/
RPC node: http://mysterious-sea.picoctf.net:64343
Provided file: IntOverflowBank.sol

### Core lesson

Solidity versions before 0.8.x do NOT automatically protect arithmetic from
overflow and underflow.

In this contract, the vulnerable line is:
balances[msg.sender] = balances[msg.sender] + amount;

The developer tries to detect overflow after the fact with:
if (!revealed && balances[msg.sender] < amount) {
revealed = true;
emit FlagRevealed(flag);
}

That condition is actually reachable because uint256 arithmetic wraps modulo
2^256 in Solidity 0.6.12.

### Real-world analogy

Think of an odometer in a car. If it had only a few digits and you kept adding
more mileage past the maximum value, it would roll over back near zero.

That is exactly what happens here:
1 + (2^256 - 1) = 0   mod 2^256

Once the wrapped result becomes smaller than the deposited amount, the
contract's "overflow detector" reveals the flag.

### Step 1: Read the contract.

Manual command:
sed -n '1,260p' IntOverflowBank.sol

Reason:
The key functions are:
- deposit(uint256 amount)
- getFlag()

The exploit path is entirely inside deposit(). No ether transfer is required.
The contract only updates an internal mapping.

### Step 2: Understand why one deposit is not enough.

Manual concept:
Starting balance = 0

If we call:
deposit(MAX_UINT256)

then:
0 + (2^256 - 1) = 2^256 - 1

That does NOT overflow, because the result is still within uint256 range.

So we first need a non-zero balance.

### Step 3: Make a tiny first deposit.

Manual command:
deposit(1)

Reason:
After this call:
balances[player] = 1

Now the next huge deposit can overflow.

### Step 4: Trigger the overflow.

Manual command:
deposit(2^256 - 1)

Reason:
In uint256 arithmetic:
1 + (2^256 - 1) = 2^256 = 0 mod 2^256

So after the second deposit:
balances[player] = 0

The contract then evaluates:
if (balances[msg.sender] < amount)

which becomes:
if (0 < 2^256 - 1)

That is true, so:
- revealed = true
- the flag becomes accessible through getFlag()

### Step 5: Read the flag.

Manual command:
call getFlag()

Reason:
Once revealed is true, getFlag() stops reverting and returns the stored flag
string.

### Step 6: Why the private key matters.

Manual concept:
The challenge page gives us:
- contract address
- player address
- player private key

We use the private key to sign transactions from the funded player account.
This is similar to having a challenge wallet in a local lab environment.

Real-world security lesson:
Smart contracts must not rely on unchecked arithmetic in older Solidity
versions. In production, the fix would be one of these:
- upgrade to Solidity 0.8+
- use SafeMath in older versions
- validate arithmetic boundaries before updating state

### Flag obtained

picoCTF{Sm4r7_OverFL0ws_ExI5t_728375ba}

## Reproduction Commands

Use this sequence if you want the shortest path from opening the folder to reproducing the saved solve:

```bash
cd "/home/eliah/Desktop/CTF/picoCTF/Smart_Overflow"
sed -n "1,220p" "smart_overflow_poc.sh"
bash "smart_overflow_poc.sh"
```

## Study Notes

This folder is best used as a practical study reference for `Blockchain`-style problems. The fastest path is to run the PoC, but the more valuable path is to read the solve notes first, inspect the local files yourself, and then compare your reasoning to the saved exploit or script.
