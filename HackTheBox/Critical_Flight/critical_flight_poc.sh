#!/usr/bin/env bash

set -euo pipefail

# Challenge: Critical Flight
# Category: Hardware
# Platform: Hack The Box CTF Try Out
#
# Files provided:
#   - hw_critical_flight.zip
#   - extracted Gerber PCB production files under flight_control_board/
#
# What this challenge teaches:
# Gerber files are the manufacturing blueprints used to fabricate PCBs.
# They are layer-based. A single board is usually split into:
#   - top copper
#   - bottom copper
#   - inner copper layers
#   - silkscreen
#   - solder mask
#   - edge cuts
#
# In real hardware reviews, sabotage can be hidden inside a layer that is not
# obvious in the fully combined board view. That makes layer isolation an
# important forensic skill.
#
# The intended solve:
#   1. Open the Gerber set in a viewer.
#   2. Toggle layers on and off.
#   3. Notice that the flag is split across different copper layers.
#   4. The useful layers are:
#        - HadesMicro-B_Cu.gbr
#        - HadesMicro-In1_Cu.gbr
#   5. Combine the visible text fragments from those layers.
#
# Why this matters in the real world:
# A PCB can be tampered with in ways that are invisible if you only inspect the
# final assembled image. Hidden traces, copper art, antennas, coils, debug
# backdoors, or covert markings can be buried inside internal layers. Reviewing
# only the top silkscreen is not enough.
#
# In this challenge, the "suspicious alteration" is hidden textual artwork in
# the copper layers. When the relevant layers are viewed, the two halves of the
# flag become visible and must be concatenated.
#
# Reproduction notes:
#   - We rendered the board locally and identified the relevant data in:
#       flight_control_board/HadesMicro-B_Cu.gbr
#       flight_control_board/HadesMicro-In1_Cu.gbr
#   - The final reconstructed flag is:
#       HTB{533_7h3_1nn32_w02k1n95_0f_313c720n1c5#$@}
#
# Manual workflow example:
#   1. Load the Gerber bundle into a PCB/Gerber viewer
#   2. Hide all layers
#   3. Show only B_Cu and note the first fragment:
#        HTB{533_7h3_1nn32_w02k1n95
#   4. Show In1_Cu and note the second fragment:
#        _0f_313c720n1c5#$@}
#   5. Join them into the final flag

printf '%s\n' 'HTB{533_7h3_1nn32_w02k1n95_0f_313c720n1c5#$@}'
