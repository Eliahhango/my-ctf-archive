#!/usr/bin/env bash

set -euo pipefail

# Challenge: Don't Panic!
# Platform: Hack The Box
# Category: Reversing
#
# Full scenario:
# You've cut a deal with the Brotherhood; if you can locate and retrieve their
# stolen weapons cache, they'll provide you with the kerosene needed for your
# makeshift explosives for the underground tunnel excavation.
# The team has tracked the unique energy signature of the weapons to a small
# vault, currently being occupied by a gang of raiders who infiltrated the
# outpost by impersonating commonwealth traders.
# Using experimental stealth technology, you've slipped by the guards and
# arrive at the inner sanctum. Now, you must find a way past the highly
# sensitive heat-signature detection robot.
# Can you disable the security robot without setting off the alarm?
#
# Provided files:
#   - rev_dontpanic.zip
#   - rev_dontpanic/dontpanic
#
# Reversing summary:
# The Rust binary trims the input newline, asserts the message length is 31,
# and then dispatches each byte to one of 31 tiny checker functions.
# Each checker simply compares the byte against a fixed constant and panics if
# it does not match, so reading the per-position constants reveals the flag.
#
# Final flag obtained during testing:
#   HTB{d0nt_p4n1c_c4tch_the_3rror}

python3 - <<'PY'
# Recovered by reading the 31 per-byte checker functions in src::check_flag.
flag = "HTB{d0nt_p4n1c_c4tch_the_3rror}"
print(flag)
PY
