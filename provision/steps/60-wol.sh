#!/usr/bin/env bash
# Enable Wake-on-LAN on the wired NIC (docs/07). Pairs with BIOS "Resume By
# PCI-E Device = Enabled" + "ErP Ready = Disabled".
set -euo pipefail
source "$HERE/config.env"

if [[ "${ENABLE_WOL:-false}" != "true" ]]; then
  echo "ENABLE_WOL!=true — skipping."; exit 0
fi

nic="${NIC:-}"
if [[ -z "$nic" ]]; then
  nic="$(ip -o route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
  [[ -z "$nic" ]] && nic="$(ls /sys/class/net | grep -E '^(en|eth)' | head -1)"
fi
if [[ -z "$nic" ]]; then echo "No wired NIC found. Skipping." >&2; exit 0; fi
echo "WOL NIC = $nic"

# Persist across reboots with a oneshot service (ethtool setting is not sticky).
cat > /etc/systemd/system/wol@.service <<'EOF'
[Unit]
Description=Enable Wake-on-LAN on %i
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
ExecStart=/usr/sbin/ethtool -s %i wol g
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now "wol@${nic}.service"
ethtool "$nic" | grep -i wake || true
echo "WOL armed on $nic (mode g). Wake with: wakeonlan <MAC>"
