#!/usr/bin/env bash
# Fan control via lm-sensors. The Lian Li hub's PWM is driven by one motherboard
# header (MSI B550 = nct6775 hwmon). Full auto-mapping isn't possible unattended
# (pwmconfig is interactive), so this preps sensors and leaves a documented curve.
set -euo pipefail
source "$HERE/config.env"
export DEBIAN_FRONTEND=noninteractive

if [[ "${SETUP_FANCONTROL:-false}" != "true" ]]; then
  echo "SETUP_FANCONTROL!=true — skipping."; exit 0
fi

apt-get install -y lm-sensors fancontrol
# MSI B550 Super I/O hwmon:
modprobe nct6775 2>/dev/null || true
grep -qxF nct6775 /etc/modules 2>/dev/null || echo nct6775 >> /etc/modules
yes "" | sensors-detect --auto >/dev/null 2>&1 || sensors-detect --auto || true

cat <<'NOTE'
lm-sensors installed. To bind the Lian Li hub's PWM header to a CPU-temp curve:
  1) sudo pwmconfig      # interactive: identify which pwmN spins the fans
  2) it writes /etc/fancontrol ; then: sudo systemctl enable --now fancontrol

Target curve (docs/09 "StandardSpeed", per-fan RPM vs CPU temp):
    25C=420  40C=1050  55C=1302  70C=1575  90C=2100   (min 210 / max 2100)

Simplest alternative: set this same curve in MSI Click BIOS (Hardware Monitor)
on the header the controller plugs into, and skip fancontrol entirely.
NOTE
echo "fancontrol prep done."
