#!/usr/bin/env bash
# Flash the compute-monster restore ISO to the MemorySaver USB (macOS).
# Needs sudo (raw disk write). Run:  sudo bash flash-usb.sh
# Verifies the target is a REMOVABLE disk named MEMORYSAVER before writing,
# so it can't clobber an internal drive.
set -euo pipefail

ISO="${ISO:-$HOME/Downloads/compute-monster-restore.iso}"
[[ -f "$ISO" ]] || ISO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/compute-monster-restore.iso"
WANT_NAME="${WANT_NAME:-MEMORYSAVER}"

[[ -f "$ISO" ]] || { echo "ISO not found: $ISO"; exit 1; }

# Find the disk whose media name is MEMORYSAVER and is removable.
DEV=""
for d in $(diskutil list | awk '/^\/dev\/disk[0-9]+ \(external, physical\)/{print $1}'); do
  name=$(diskutil info "$d" | awk -F': *' '/Device \/ Media Name/{print $2}' | xargs)
  rem=$(diskutil info "$d" | awk -F': *' '/Removable Media/{print $2}' | xargs)
  if [[ "$name" == "$WANT_NAME" ]]; then DEV="$d"; echo "target: $d  ($name, removable=$rem)"; break; fi
done
[[ -n "$DEV" ]] || { echo "No removable disk named '$WANT_NAME' found. Aborting."; exit 1; }

RAW="${DEV/disk/rdisk}"   # raw node = much faster
echo "About to ERASE $DEV and write:"
echo "  $ISO"
echo "  -> $RAW"
echo "Ctrl-C now to abort; writing in 5s..."; sleep 5

diskutil unmountDisk "$DEV"
dd if="$ISO" of="$RAW" bs=4m
sync
diskutil eject "$DEV" || true
echo "DONE. USB '$WANT_NAME' is now the compute-monster restore stick."
