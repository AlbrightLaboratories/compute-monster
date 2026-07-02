#!/usr/bin/env bash
# OpenRGB + the red-meteor animator as a headless systemd service.
# Reproduces the documented look (docs/09): outer ring = red Meteor, inner = solid red.
set -euo pipefail
source "$HERE/config.env"
export DEBIAN_FRONTEND=noninteractive

if [[ "${ENABLE_RGB_METEOR:-false}" != "true" ]]; then
  echo "ENABLE_RGB_METEOR!=true — skipping RGB."; exit 0
fi

# OpenRGB (universe) — ships the udev rules that give non-root access to the hub.
add-apt-repository -y universe || true
apt-get update -y
apt-get install -y openrgb || {
  echo "apt openrgb failed; grab the .deb from https://openrgb.org and 'apt install ./OpenRGB*.deb'." >&2
  exit 1
}
udevadm control --reload-rules && udevadm trigger || true

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
systemctl enable --now openrgb-server.service
systemctl enable --now openrgb-meteor.service

echo
echo "RGB services up. Check: systemctl status openrgb-meteor"
echo "If the hub isn't detected, run once interactively:"
echo "  $APP/venv/bin/python $APP/meteor.py --list"
echo "and set LED-mapping in $APP/meteor.conf per docs/09 (inner vs outer ring)."
