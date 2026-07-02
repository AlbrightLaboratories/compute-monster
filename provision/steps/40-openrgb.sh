#!/usr/bin/env bash
# OpenRGB + the red-meteor animator as a headless systemd service.
# Reproduces the documented look (docs/09): outer ring = red Meteor, inner = solid red.
set -euo pipefail
source "$HERE/config.env"
export DEBIAN_FRONTEND=noninteractive

if [[ "${ENABLE_RGB_METEOR:-false}" != "true" ]]; then
  echo "ENABLE_RGB_METEOR!=true — skipping RGB."; exit 0
fi

# OpenRGB is NOT in Ubuntu's repos — install the upstream .deb (the Debian bookworm
# build runs fine on Ubuntu 24.04/noble). apt resolves its deps + installs udev rules.
# Use 1.0rc3: stable 0.9 does NOT detect the Lian Li SL-Infinity v1.4 hub (0cf2:a102),
# only the Corsair RAM; the newer build has the SL-Infinity detector.
OPENRGB_DEB_URL="${OPENRGB_DEB_URL:-https://codeberg.org/OpenRGB/OpenRGB/releases/download/release_candidate_1.0rc3/openrgb_1.0rc3_amd64_bookworm_6fbcf62.deb}"
want_ver="1.0rc3"
have_ver="$(openrgb --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(rc[0-9]+)?' | head -1 || true)"
if [[ "$have_ver" != "$want_ver" ]]; then
  echo "installing OpenRGB $want_ver (have: ${have_ver:-none})"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/openrgb.deb" "$OPENRGB_DEB_URL"
  apt-get -o DPkg::Lock::Timeout=300 install -y --allow-downgrades "$tmp/openrgb.deb"
  rm -rf "$tmp"
fi
command -v openrgb >/dev/null || { echo "openrgb install failed ($OPENRGB_DEB_URL)"; exit 1; }
udevadm control --reload-rules && udevadm trigger || true
sleep 2  # let udev settle so the hub is accessible

APP=/opt/openrgb-meteor
mkdir -p "$APP"
python3 -m venv "$APP/venv"
"$APP/venv/bin/pip" install --upgrade pip >/dev/null
"$APP/venv/bin/pip" install openrgb-python >/dev/null
install -m 0755 "$HERE/rgb/meteor.py" "$APP/meteor.py"

# Config for the animator, derived from config.env / docs/09.
cat > "$APP/meteor.conf" <<EOF
COLOR=$RGB_COLOR
TAIL=$RGB_TAIL
SPEED=$RGB_SPEED
BRIGHTNESS=$RGB_BRIGHTNESS
BACKGROUND_RED=$RGB_BACKGROUND_RED
EOF

# OpenRGB SDK server (headless).
cat > /etc/systemd/system/openrgb-server.service <<'EOF'
[Unit]
Description=OpenRGB SDK server (headless)
After=multi-user.target
[Service]
ExecStart=/usr/bin/openrgb --server --server-port 6742 --noautoconnect
Restart=on-failure
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

# Meteor animator (connects to the local server).
cat > /etc/systemd/system/openrgb-meteor.service <<EOF
[Unit]
Description=Red meteor RGB animation (compute-monster)
Requires=openrgb-server.service
After=openrgb-server.service
[Service]
EnvironmentFile=$APP/meteor.conf
ExecStartPre=/bin/sleep 3
ExecStart=$APP/venv/bin/python $APP/meteor.py
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openrgb-server.service openrgb-meteor.service
# restart (not just --now) so an upgraded binary + config are picked up
systemctl restart openrgb-server.service
sleep 2
systemctl restart openrgb-meteor.service

echo
echo "RGB services up. Check: systemctl status openrgb-meteor"
echo "If the hub isn't detected, run once interactively:"
echo "  $APP/venv/bin/python $APP/meteor.py --list"
echo "and set LED-mapping in $APP/meteor.conf per docs/09 (inner vs outer ring)."
