#!/usr/bin/env bash

set -euo pipefail

# Challenge: Debug
# Category: Hardware
# Platform: Hack The Box CTF Try Out
#
# Given file:
#   - hw_debug.sal
#
# What this challenge is about:
# The provided file is a Saleae Logic capture (.sal). These files are commonly
# used with logic analyzers to inspect digital signals such as UART, SPI, I2C,
# and raw GPIO activity.
#
# The scenario explicitly mentions:
#   - a debugging interface
#   - a serial signal captured during boot
# That strongly suggests UART / async serial.
#
# Why UART is the right direction:
# The capture metadata shows two digital lines named:
#   - TX
#   - RX
# Those are the standard names for serial transmit and receive lines.
#
# Intended solve in Logic 2 / Saleae:
#   1. Open hw_debug.sal in Logic 2
#   2. Focus on the RX line
#   3. Add an "Async Serial" analyzer
#   4. Determine baud rate by measuring the width of a single bit pulse
#   5. The bit width is about 8.68 microseconds
#   6. Baud rate is therefore:
#        1 / 0.00000868 ≈ 115200
#   7. Use:
#        - Baud: 115200
#        - 8 data bits
#        - no parity
#        - 1 stop bit
#   8. Read the boot log / terminal output
#
# What appears near the end of the decoded serial text:
#
#   WARNING: The deep space observatory is offline HTB{
#   INFO: Communication systems are offline reference code: 547311173_
#   WARNING: Unauthorized subroutines detected! reference code: n37w02k_
#   WARNING: The satellite dish can not sync with the swarm. reference code: c0mp20m153d}
#
# Reconstructing the flag from those lines gives:
#   HTB{547311173_n37w02k_c0mp20m153d}
#
# Real-world lesson:
# When hardware or embedded devices expose debug serial output, developers often
# leak highly sensitive internal state during boot:
#   - credentials
#   - firmware status
#   - crash details
#   - internal references
#   - secret tokens
# Even "harmless" logs can become a full compromise if the interface is left
# accessible.
#
# Manual reproduction:
#   - open the capture in Logic 2
#   - add Async Serial on RX
#   - set baud to 115200
#   - inspect decoded output near the end of the capture
#
# Flag obtained:
# HTB{547311173_n37w02k_c0mp20m153d}

printf '%s\n' 'HTB{547311173_n37w02k_c0mp20m153d}'
