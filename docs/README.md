# compute-monster — hardware docs

Manufacturer-verified hardware reference for the **compute-monster** build — the single **AM4 / DDR4** node that consolidates and retires cluster workers **kubeadm-worker04**, **kubeadm-worker06**, and **kubeadm-worker07**.

> **Platform note:** this was originally scoped as an AM5/DDR5 ASUS B650E build. That board wouldn't POST after transplant, so the build was **downgraded to AM4/DDR4** and reassembled around a locally-bought **MSI B550-A PRO + Ryzen 7 5800X + RTX 3060 Ti**. The box now POSTs and runs; these docs reflect the **as-built** machine.

Every spec is sourced from the **official manufacturer** (MSI, AMD), per the operator rule "check the official documentation FIRST." Where a figure isn't officially published, it's flagged — no invented numbers.

## Index

| Doc | Covers |
|-----|--------|
| [01-hardware-bom.md](01-hardware-bom.md) | Full as-built bill of materials |
| [02-motherboard-msi-b550-a-pro.md](02-motherboard-msi-b550-a-pro.md) | MSI board — memory, M.2/SATA, LAN, EZ Debug LEDs, BIOS |
| [03-cpu-ryzen-7-5800x.md](03-cpu-ryzen-7-5800x.md) | AMD Ryzen 7 5800X — specs, DDR4 rating, **no-iGPU gotcha**, thermals |
| [04-memory-ddr4.md](04-memory-ddr4.md) | 64 GB DDR4 — type rules, Zen 3 DDR4-3600 sweet spot |
| [05-memory-sizing-proper-path.md](05-memory-sizing-proper-path.md) | Why 64 GB is right for absorbing 3 workers |
| [06-assembly-and-bios-setup.md](06-assembly-and-bios-setup.md) | As-built check, MSI BIOS/A-XMP/WOL, **wipe Windows → Linux → cluster join** |
| [07-power-cost-and-cold-tiering.md](07-power-cost-and-cold-tiering.md) | **Electricity plan (Kissimmee/KUA):** what stays hot, goes cold, gets retired |
| [08-case-and-fan-placement.md](08-case-and-fan-placement.md) | Case, **AIO radiator mounting**, fan placement, and **RGB lighting (colors + chasing effect + keeping it under Linux)** |
| [09-rgb-and-fan-profile.md](09-rgb-and-fan-profile.md) | **Decoded L-Connect export** — the actual red Door/Meteor scheme + fan curves, for reproducing on Linux |

## Provisioning / restore ISO

Automated build-out lives in [`../provision/`](../provision/README.md): an unattended
Ubuntu 24.04 **restore ISO** (`build-iso.sh` → `flash-usb.sh`) plus a first-boot
`bootstrap.sh` that installs the NVIDIA driver, mounts, WOL, k8s prereqs, and the
red-meteor RGB service — boot the USB and walk away.

## The one-paragraph answer

The Ryzen 7 5800X (16 threads) crushes the CPU side — the three retiring workers total ~11 vCPU and use ~1.8 cores live. **Memory was the constraint**, and the box already carries **64 GB DDR4**, which beats the ~49 GiB of combined capacity being retired with ~4× burst headroom. The box POSTs with an **RTX 3060 Ti** (mandatory — the 5800X has no iGPU), boots off a **1 TB NVMe**, and has a **2 TB Seagate** for bulk. Remaining work is software: **wipe Windows, install Linux, join the cluster** ([06](06-assembly-and-bios-setup.md)).
