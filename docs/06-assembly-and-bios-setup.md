# 06 — Assembly, BIOS, and go-live (wipe Windows → Linux → cluster)

The box is **built and POSTing** (MSI B550-A PRO + Ryzen 7 5800X + 64 GB DDR4 + RTX 3060 Ti + 1 TB NVMe + 2 TB Seagate + AIO). What remains is: set BIOS, **wipe Windows, install Linux, and join the cluster.**

---

## As-built checklist (already done — verify)

- [x] **CPU** Ryzen 7 5800X seated (gold triangle to socket corner).
- [x] **AIO cooler** mounted — **radiator above the CPU (top) or front-mounted tubes-at-bottom**, so air can't pool in the pump ([03](03-cpu-ryzen-7-5800x.md) / [08](08-case-and-fan-placement.md)). Pump powered from a `PUMP_FAN`/`CPU_FAN` header set to full/PWM.
- [x] **64 GB DDR4** installed (2×32 in DIMMA2/B2, or 4×16 all slots).
- [x] **RTX 3060 Ti** in the PCIe 4.0 x16 slot — **the only source of video** on this CPU; monitor cable goes to the **card**, not the board.
- [x] **1 TB NVMe** in **M2_1** (PCIe 4.0 x4, CPU) — boot/data.
- [x] **2 TB Seagate HDD** on a **SATA** port (+ SATA power).
- [x] **PSU**: 24-pin + **8-pin EPS** (top-left) + PCIe power to the 3060 Ti.
- [x] Box **POSTs** — the white VGA EZ Debug LED cleared once the GPU went in.

## First POST readout — EZ Debug LEDs

The MSI board has 4 LEDs (no numeric code): **CPU (red) · DRAM (yellow) · VGA (white) · BOOT (green)**. If a boot ever hangs, whichever LED stays lit names the stage:
- **DRAM (yellow):** reseat RAM / try one stick in DIMMA2; loosen memory speed.
- **VGA (white):** GPU/display issue (or a dislodged card) — this CPU has no fallback iGPU.
- **CPU (red):** reseat CPU / check the 8-pin EPS.
- **BOOT (green):** POST OK, boot-device problem (see boot order below).

---

## BIOS settings (MSI Click BIOS 5 — press Delete at power-on)

1. **Confirm it sees everything:** 5800X, 64 GB RAM, the NVMe, and the Seagate.
2. **Memory — enable A-XMP:** top of the BIOS, click the **A-XMP** toggle (or **OC → Extreme Memory Profile (A-XMP) → Profile 1**). Target **DDR4-3600 1:1** if the kit supports it, else run its rated 3200. Save, reboot, confirm it holds. ([04](04-memory-ddr4.md))
3. **Wake-on-LAN (if this node will cold/WOL later):**
   - **Settings → Advanced → Power Management Setup → ErP Ready = Disabled**
   - **Settings → Advanced → Wake Up Event Setup → Resume By PCI-E Device = Enabled**
4. **Boot order:** set the **1 TB NVMe** first once the OS is on it.
5. **F10** to save & exit.

> **Memory training** after a RAM change makes the *first* boot slow (black screen up to ~1–2 min). DDR4 trains far faster than DDR5 — wait it out, don't cut power.

---

## Wipe Windows → install Linux

The box came with Windows (pawnshop drive). Replace it with the cluster's Linux baseline on the **1 TB NVMe**.

> **RGB caution before wiping:** L-Connect 3 (Lian Li) is Windows-only, and a **custom effect driven by L-Connect does NOT reliably persist** — if the lighting resets to default rainbow on reboot, it lives only in software and **wiping Windows loses it.** Make it Windows-free FIRST (controller hardware button, or OpenRGB on Linux) and **prove it survives a reboot before you wipe.** Full guide: [08](08-case-and-fan-placement.md).

1. **Build a Linux installer USB** on another machine — **Ubuntu 24.04 LTS** (match the cluster / kubeadm baseline). Use Rufus (Windows) or `dd`/Balena Etcher.
2. Boot it: power on → tap **F11** for the MSI boot menu → pick the **UEFI: USB** entry.
3. Choose **Install Ubuntu → Erase disk and install Ubuntu**, and select the **1 TB NVMe** as the target. This wipes Windows entirely.
   - Leave the **2 TB Seagate** unselected during install; mount it afterward as a data disk (`/data`) — `mkfs.ext4`, add to `/etc/fstab` by UUID.
4. Finish install, remove USB, boot into Ubuntu.
5. **Arm WOL on Linux** (if wanted): `sudo ethtool -s <iface> wol g`, persist via systemd-networkd. ([07](07-power-cost-and-cold-tiering.md))

---

## Join the cluster

- [ ] Install the container runtime + `kubeadm`/`kubelet`/`kubectl` at the cluster's version.
- [ ] Set **`--max-pods ~160`** in the kubelet config (3 retiring nodes total 143 pods > default 110). See [05](05-memory-sizing-proper-path.md).
- [ ] **`kubeadm join`** with the cluster token.
- [ ] `kubectl get nodes` → the new node shows **Ready**. It's schedulable and taking workloads. ✅

## Validation before you rely on it

- [ ] RAM: `sudo dmidecode -t memory` shows the full 64 GB at the expected speed.
- [ ] CPU temps under load stay **below 90 °C** (`sensors` + `stress-ng --cpu 16`). The AIO should hold it; brief 90 °C touches are normal for a 5800X.
- [ ] GPU visible: `nvidia-smi` lists the RTX 3060 Ti (after installing the NVIDIA driver + container toolkit if the node runs GPU workloads).
- [ ] A short MemTest/`memtester` pass if you pushed memory above rated speed.
