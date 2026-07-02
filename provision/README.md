# compute-monster — provisioning & restore ISO

Turns a bare box into a ready compute-monster node with **one boot**: an unattended
Ubuntu 24.04 autoinstall that wipes the NVMe, installs the OS, then runs a first-boot
bootstrap that sets up the **NVIDIA driver, disk mounts, Wake-on-LAN, k8s prereqs,
and the red-meteor RGB service** — all parameterized from the documented inventory.

## What's here

| Path | Purpose |
|------|---------|
| `config.env` | Inventory-derived knobs (GPU, disks, NIC, RGB, k8s). Edit here. |
| `bootstrap.sh` | Orchestrator — runs the `steps/` in order. Idempotent. |
| `steps/10-base.sh` | apt update + essentials + hostname |
| `steps/20-nvidia.sh` | NVIDIA driver (RTX 3060 Ti) + optional container toolkit |
| `steps/30-storage.sh` | mount the 2 TB Seagate at `/data` (leaves boot NVMe alone) |
| `steps/40-openrgb.sh` | OpenRGB + red-meteor `systemd` services (docs/09 look) |
| `steps/50-fancontrol.sh` | lm-sensors + StandardSpeed fan curve prep |
| `steps/60-wol.sh` | Wake-on-LAN on the wired NIC |
| `steps/70-kube-prereqs.sh` | containerd + kubeadm/kubelet/kubectl + max-pods |
| `rgb/meteor.py` | headless red-meteor animator via the OpenRGB SDK |
| `autoinstall/user-data` | template autoinstall seed (creds filled by `build-iso.sh`) |
| `build-iso.sh` | build the unattended **restore ISO** from a stock Ubuntu ISO |
| `flash-usb.sh` | write the ISO to the MemorySaver USB (macOS, safety-checked) |
| `backups/` | preserved L-Connect export (rescued off the USB before flashing) |

## The restore ISO (the "boot and walk away" path)

1. **Build** (already done once → `~/Downloads/compute-monster-restore.iso`):
   ```sh
   PASSWORD='<account-pw>' USERNAME=a_guy TZ=America/New_York ./build-iso.sh
   ```
2. **Flash** to USB (needs sudo — raw disk write):
   ```sh
   sudo bash flash-usb.sh          # verifies target is the MEMORYSAVER stick
   ```
3. **Boot** the compute-monster from the USB (F11 → UEFI: USB). It auto-selects
   **"AUTOINSTALL compute-monster"**, wipes `/dev/nvme0n1`, installs Ubuntu 24.04,
   reboots, and the first-boot service runs `bootstrap.sh`. Done hands-off.

> ⚠️ The ISO **wipes the 1 TB NVMe** (`/dev/nvme0n1`). The 2 TB Seagate is left
> alone and mounted afterward. Verify the NVMe path if hardware changed.

## Run the bootstrap by itself (no reinstall)

On an already-installed box:
```sh
sudo ./bootstrap.sh            # everything
sudo ./bootstrap.sh 40         # just the RGB meteor, etc.
```

## Reference

Hardware + decisions in [`../docs/`](../docs/README.md). The RGB look and fan curves
this reproduces are decoded in [`../docs/09-rgb-and-fan-profile.md`](../docs/09-rgb-and-fan-profile.md).
