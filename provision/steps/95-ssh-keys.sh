#!/usr/bin/env bash
# Authorized SSH keys for a_guy — passwordless access from trusted machines.
set -uo pipefail
source "$HERE/config.env"
u="${RUNNER_USER:-a_guy}"
h="/home/$u"
mkdir -p "$h/.ssh"
grep -qxF "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO40L3TGmonYbPOJs3bkI0kjpBvoPtHtVn7w9yixRmiu hawaiideveloper@gmail.com" "$h/.ssh/authorized_keys" 2>/dev/null || \
  echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO40L3TGmonYbPOJs3bkI0kjpBvoPtHtVn7w9yixRmiu hawaiideveloper@gmail.com" >> "$h/.ssh/authorized_keys"
chown -R "$u:$u" "$h/.ssh"
chmod 700 "$h/.ssh"; chmod 600 "$h/.ssh/authorized_keys"
echo "authorized_keys updated ($(wc -l < "$h/.ssh/authorized_keys") key(s))"
