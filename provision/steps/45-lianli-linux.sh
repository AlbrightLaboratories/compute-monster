#!/usr/bin/env bash
# lianli-linux (github.com/sgtaziz/lian-li-linux) — open-source L-Connect 3
# replacement. OpenRGB (rc3 AND master) cannot drive the SL-Infinity v1.4 hub's
# LEDs (writes no-op; fans stay on hub-default rainbow); this project's driver
# is tested against the SL Infinity with working RGB.
set -uo pipefail
source "$HERE/config.env"
export DEBIAN_FRONTEND=noninteractive
RUNNER_U="${RUNNER_USER:-a_guy}"

# --- retire the OpenRGB services (would fight over the hub's hidraw) ---
systemctl disable --now openrgb-meteor.service openrgb-server.service 2>/dev/null || true

# --- build deps (evdi only needed for LCD devices; we have none, but the
#     daemon links libevdi, so install the dev lib) ---
apt-get update -y
apt-get install -y libhidapi-dev libusb-1.0-0-dev libudev-dev libfontconfig-dev \
  libxkbcommon-dev libwayland-dev libx11-dev libinput-dev libdrm-dev \
  libgl-dev libegl-dev clang cmake pkg-config ffmpeg nasm \
  libavcodec-dev libavformat-dev libswscale-dev libavutil-dev \
  libevdi0-dev git curl || {
    echo "dep install failed (libevdi0-dev missing on noble?) — trying without it"
    apt-get install -y libhidapi-dev libusb-1.0-0-dev libudev-dev libfontconfig-dev \
      libxkbcommon-dev libwayland-dev libx11-dev libinput-dev libdrm-dev \
      libgl-dev libegl-dev clang cmake pkg-config ffmpeg nasm \
      libavcodec-dev libavformat-dev libswscale-dev libavutil-dev git curl
  }

# --- rust toolchain (self-contained under /opt, no $HOME assumptions) ---
export RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo
if [[ ! -x /opt/cargo/bin/cargo ]]; then
  curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable
fi
export PATH="/opt/cargo/bin:$PATH"

# --- clone + build ---
SRC=/opt/lian-li-linux
if [[ ! -d "$SRC/.git" ]]; then
  git clone --recurse-submodules https://github.com/sgtaziz/lian-li-linux.git "$SRC"
else
  git -C "$SRC" pull --recurse-submodules || true
fi
cd "$SRC"
if [[ ! -x target/release/lianli-daemon ]]; then
  cargo build --release -p lianli-daemon 2>&1 | tail -5 || cargo build --release 2>&1 | tail -5
fi
[[ -x target/release/lianli-daemon ]] || { echo "lianli-daemon build FAILED"; exit 1; }

# --- install ---
install -Dm755 target/release/lianli-daemon /usr/bin/lianli-daemon
install -Dm644 packaging/udev/99-lianli.rules /etc/udev/rules.d/99-lianli.rules
install -Dm644 packaging/systemd/lianli-daemon.service /usr/lib/systemd/user/lianli-daemon.service 2>/dev/null || true
udevadm control --reload-rules && udevadm trigger

# --- run as the login user's service (headless via linger) ---
loginctl enable-linger "$RUNNER_U" || true
u_id="$(id -u "$RUNNER_U")"
sudo -u "$RUNNER_U" XDG_RUNTIME_DIR="/run/user/$u_id" systemctl --user daemon-reload || true
sudo -u "$RUNNER_U" XDG_RUNTIME_DIR="/run/user/$u_id" systemctl --user enable --now lianli-daemon.service || true
sleep 5
sudo -u "$RUNNER_U" XDG_RUNTIME_DIR="/run/user/$u_id" systemctl --user is-active lianli-daemon.service || true

# --- dump the auto-generated config so the RGB effect schema is visible in CI ---
echo "===== default config.json (for schema) ====="
cat "/home/$RUNNER_U/.config/lianli/config.json" 2>/dev/null || echo "(config not created yet)"
echo "===== daemon log tail ====="
sudo -u "$RUNNER_U" XDG_RUNTIME_DIR="/run/user/$u_id" journalctl --user -u lianli-daemon --no-pager 2>/dev/null | tail -15 || true
echo "lianli-linux installed."
