#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: Welcome to CTF
# Category: Warmup
# Platform: Hack The Box
#
# Description:
# This is the onboarding warmup scenario shown when you first spawn the target.
# The goal is simply to connect to the provided service and recover the first
# flag.
#
# Given information from the platform:
# Spawned target: 154.57.164.72:30484
# Browser hint: "Play through the browser"
#
# Core lesson:
# Not every challenge starts with exploitation. Sometimes the first task is just
# service identification and careful observation.
#
# In this warmup, the homepage itself contains the flag in the rendered HTML.
# The challenge teaches the basic workflow:
# - verify the service
# - inspect the response
# - extract the flag
#
# Step 1: Identify the service.
# Manual command:
# nmap -sV -Pn -p 30484 154.57.164.72
#
# Reason:
# This shows the target is a Python Werkzeug HTTP service, so the natural next
# step is to browse it or request it over HTTP.
#
# Step 2: Request the homepage.
# Manual command:
# curl -s http://154.57.164.72:30484/
#
# Reason:
# The landing page returns a simple HTML onboarding screen. It includes the
# message:
# "Congratulations, you've got your first flag."
#
# Step 3: Extract the flag from the HTML.
# Manual command:
# curl -s http://154.57.164.72:30484/ | grep -o 'HTB{[^}]*}'
#
# Reason:
# The flag is embedded directly in the page source, so a simple grep is enough
# to recover it cleanly.
#
# Real-world concept:
# This is a basic reminder that sensitive values can leak directly into client
# responses. Before testing anything more advanced, always inspect what the
# application already gives you.
#
# Flag obtained:
# HTB{onboard1ng_fl4g}

host="${1:-154.57.164.72}"
port="${2:-30484}"

curl -s "http://${host}:${port}/" | grep -o 'HTB{[^}]*}'
