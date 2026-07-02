#!/usr/bin/env bash
# Grant the runner/login user passwordless sudo so CI (running as that user) can
# provision as root. This step runs as ROOT via the provisioning service, so it
# needs no password — this is what breaks the "CI can't sudo" bootstrap wall.
set -uo pipefail
source "$HERE/config.env"
u="${RUNNER_USER:-a_guy}"

if ! id "$u" >/dev/null 2>&1; then
  echo "user '$u' not found — skipping sudo grant"; exit 0
fi
echo "$u ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-compute-monster-runner
chmod 440 /etc/sudoers.d/99-compute-monster-runner
# Validate the sudoers file so a typo can never lock out sudo.
if visudo -cf /etc/sudoers.d/99-compute-monster-runner >/dev/null 2>&1; then
  echo "passwordless sudo granted to $u"
else
  echo "sudoers validation FAILED — removing" >&2
  rm -f /etc/sudoers.d/99-compute-monster-runner; exit 1
fi
