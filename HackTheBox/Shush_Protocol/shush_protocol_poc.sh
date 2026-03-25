#!/usr/bin/env bash

set -euo pipefail

# Challenge: Shush Protocol
# Category: ICS
# Platform: Hack The Box CTF Try Out
#
# Given file:
#   - traffic.pcapng
#
# Core lesson:
# This challenge is a good example of why "custom protocols" do not magically
# become secure just because they are unusual. The PLC traffic still runs over
# a familiar transport, and the password exchange is exposed in plaintext.
#
# What the capture shows:
#   - All traffic is Modbus/TCP on port 502
#   - Normal polling uses:
#       - Function 1  : Read Coils
#       - Function 3  : Read Holding Registers
#   - A custom command appears repeatedly:
#       - Function 102
#
# Why function 102 matters:
# Standard Modbus does not define function code 102 for this use here, so this
# is clearly application-specific logic added by the device vendor or developer.
# In real ICS work, that is exactly where weak authentication and unsafe design
# choices often live.
#
# By following the TCP stream that uses function 102, the capture reveals:
#   - the password: operator
#   - the flag in the PLC response after the authentication sequence succeeds
#
# Manual reproduction:
#   1. Open the capture in Wireshark
#   2. Filter:
#        modbus
#   3. Notice repeated packets with:
#        Func: 102: Unknown function (102)
#   4. Follow the TCP stream for that connection
#   5. The stream contains:
#        operator
#      and later the flag:
#        HTB{50m371m35_cu570m_p2070c01_423_n07_3n0u9h7}
#
# Useful tshark command:
#   tshark -r traffic.pcapng -z follow,tcp,ascii,1
#
# Real-world takeaway:
# Industrial protocols are often trusted because they live in "internal" or
# supposedly isolated networks. But once an attacker reaches that segment,
# plaintext secrets and home-grown protocol extensions can collapse security
# very quickly.
#
# Password recovered:
#   operator
#
# Flag obtained:
# HTB{50m371m35_cu570m_p2070c01_423_n07_3n0u9h7}

printf '%s\n' 'HTB{50m371m35_cu570m_p2070c01_423_n07_3n0u9h7}'
