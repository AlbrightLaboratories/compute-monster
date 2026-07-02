#!/usr/bin/env bash
# Install + enable the self-healing provisioner service. Idempotent.
# Used by the ISO late-commands and runnable by hand.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ $EUID -eq 0 ]] || { echo "run as root"; exit 1; }
install -m 0644 "$HERE/systemd/compute-monster-provision.service" \
  /etc/systemd/system/compute-monster-provision.service
systemctl daemon-reload
systemctl enable compute-monster-provision.service
echo "compute-monster-provision.service enabled (runs on boot until provisioned)."
