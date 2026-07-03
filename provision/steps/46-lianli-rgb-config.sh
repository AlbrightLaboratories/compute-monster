#!/usr/bin/env bash
# Write the docs/09 red-meteor profile into lianli-linux's config and restart
# the daemon. Effect: Meteor, red #FF0000 head + #DD1713 tail, speed 1 (~L-Connect
# 25/100), brightness 4 (this driver documents 0-4 = dimmest->brightest), on all
# 4 hub groups. Set once; the daemon re-applies at every boot.
set -uo pipefail
source "$HERE/config.env"
RUNNER_U="${RUNNER_USER:-a_guy}"
u_id="$(id -u "$RUNNER_U")"
CFG="/home/$RUNNER_U/.config/lianli/config.json"
HUB_SERIAL="6243168001"

mkdir -p "$(dirname "$CFG")"

# Pure red in EVERY color slot — the old #DD1713 tail (g=23,b=19) interpolated
# to a pink wash on some blades (operator report 2026-07-03).
effect='{"mode":"Meteor","colors":[[255,0,0],[255,0,0],[255,0,0],[255,0,0]],"speed":1,"brightness":4,"direction":"Clockwise","scope":"All","disabled":false}'
devices=""
for g in 0 1 2 3; do
  devices+="{\"device_id\":\"hid:${HUB_SERIAL}:group${g}\",\"mb_rgb_sync\":false,\"zones\":[{\"zone_index\":0,\"effect\":$effect,\"swap_lr\":false,\"swap_tb\":false}]}"
  [[ $g -lt 3 ]] && devices+=","
done

cat > "$CFG" <<EOF
{
  "default_fps": 30.0,
  "hid_driver": "hidapi",
  "lcds": [],
  "fan_curves": [],
  "fans": null,
  "rgb": {
    "enabled": true,
    "openrgb_server": false,
    "openrgb_port": 6743,
    "devices": [$devices]
  },
  "aio": {},
  "ene6k77": {}
}
EOF
chown "$RUNNER_U:$RUNNER_U" "$CFG"
python3 -m json.tool "$CFG" >/dev/null || { echo "config JSON invalid"; exit 1; }
echo "config written:"
cat "$CFG"

sudo -u "$RUNNER_U" XDG_RUNTIME_DIR="/run/user/$u_id" systemctl --user restart lianli-daemon.service
sleep 6
sudo -u "$RUNNER_U" XDG_RUNTIME_DIR="/run/user/$u_id" systemctl --user is-active lianli-daemon.service
echo "--- daemon journal after apply ---"
sudo -u "$RUNNER_U" XDG_RUNTIME_DIR="/run/user/$u_id" journalctl --user -u lianli-daemon --no-pager 2>/dev/null | tail -15
