#!/usr/bin/env bash
# Mount the 2TB Seagate as $DATA_MOUNT (bulk data). Boot NVMe is untouched.
set -euo pipefail
source "$HERE/config.env"

disk="${DATA_DISK:-}"
if [[ -z "$disk" ]]; then
  # Auto-pick the largest whole disk that is NOT nvme and has no mounted partitions.
  disk="$(lsblk -dpno NAME,TYPE,SIZE | awk '$2=="disk"{print $1" "$3}' \
        | grep -v nvme | sort -k2 -h | tail -1 | awk '{print $1}')" || true
fi

if [[ -z "$disk" || ! -b "$disk" ]]; then
  echo "No data disk found/auto-picked. Set DATA_DISK in config.env. Skipping." >&2
  exit 0
fi

# Safety: refuse if the disk (or a partition) is already mounted somewhere.
if lsblk -no MOUNTPOINT "$disk" | grep -q '[^[:space:]]'; then
  echo "$disk already has a mount — not touching it. Skipping." >&2
  exit 0
fi

echo "Data disk = $disk"
part="${disk}1"; [[ "$disk" == *nvme* ]] && part="${disk}p1"

if ! lsblk -no NAME "$disk" | grep -q "$(basename "$part")"; then
  echo "Partitioning $disk (single GPT partition)..."
  parted -s "$disk" mklabel gpt
  parted -s "$disk" mkpart primary "$DATA_FS" 0% 100%
  sleep 2
fi

if ! blkid "$part" >/dev/null 2>&1; then
  echo "Formatting $part as $DATA_FS..."
  mkfs."$DATA_FS" -F "$part"
fi

uuid="$(blkid -s UUID -o value "$part")"
mkdir -p "$DATA_MOUNT"
if ! grep -q "$uuid" /etc/fstab; then
  echo "UUID=$uuid  $DATA_MOUNT  $DATA_FS  defaults,nofail,x-systemd.device-timeout=10  0  2" >> /etc/fstab
fi
mount -a
echo "Mounted $part ($uuid) at $DATA_MOUNT:"
df -h "$DATA_MOUNT"
