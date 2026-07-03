#!/usr/bin/env bash
# GPU power cap (persistent) + night-train/day-serve schedule skeleton.
# - Cap: 160W (from 200W default) — cooler (~70-75C under load), ~$50/yr less at
#   KUA rates, ~10% slower training. Reversible: nvidia-smi -pl 200.
# - Schedule: 01:00 stop ollama + run /opt/compute-monster/training/train.sh if
#   present; 07:00 stop training + restart ollama. VRAM (8GB) can't hold
#   serving AND QLoRA at once, so the windows enforce the split.
set -uo pipefail
source "$HERE/config.env"
GPU_CAP_W="${GPU_CAP_W:-160}"

command -v nvidia-smi >/dev/null || { echo "nvidia-smi missing — driver step must run first"; exit 1; }

# --- persistent power cap ---
cat > /etc/systemd/system/gpu-power-cap.service <<EOF
[Unit]
Description=GPU power cap (${GPU_CAP_W}W) for 24/7 duty
After=multi-user.target
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/nvidia-smi -pm 1
ExecStart=/usr/bin/nvidia-smi -pl ${GPU_CAP_W}
[Install]
WantedBy=multi-user.target
EOF

# --- night training window (01:00) ---
mkdir -p /opt/compute-monster/training
cat > /etc/systemd/system/train-window.service <<'EOF'
[Unit]
Description=Night training window: stop serving, run training if a job exists
[Service]
Type=oneshot
ExecStart=/bin/bash -c '\
  systemctl stop ollama; \
  if [ -x /opt/compute-monster/training/train.sh ]; then \
    echo "starting training job"; /opt/compute-monster/training/train.sh; \
  else \
    echo "no training job at /opt/compute-monster/training/train.sh — skipping"; \
  fi'
EOF
cat > /etc/systemd/system/train-window.timer <<'EOF'
[Unit]
Description=Start nightly training window at 01:00
[Timer]
OnCalendar=*-*-* 01:00:00
Persistent=true
[Install]
WantedBy=timers.target
EOF

# --- day serving window (07:00) ---
cat > /etc/systemd/system/serve-window.service <<'EOF'
[Unit]
Description=Day serving window: stop training, restart ollama
[Service]
Type=oneshot
ExecStart=/bin/bash -c '\
  pkill -f /opt/compute-monster/training/train.sh 2>/dev/null; \
  systemctl start ollama; \
  echo "serving window open (ollama up)"'
EOF
cat > /etc/systemd/system/serve-window.timer <<'EOF'
[Unit]
Description=Open serving window at 07:00
[Timer]
OnCalendar=*-*-* 07:00:00
Persistent=true
[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now gpu-power-cap.service
systemctl enable --now train-window.timer serve-window.timer

echo "--- verification ---"
nvidia-smi -q -d POWER | grep -E "Current Power Limit|Default Power Limit" | head -2
systemctl list-timers train-window.timer serve-window.timer --no-pager | head -5
echo "GPU cap + schedule installed."
