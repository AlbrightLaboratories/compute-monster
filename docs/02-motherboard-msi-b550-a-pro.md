# 02 — Motherboard: MSI B550-A PRO

Official source of truth (check FIRST, always): MSI.

- Product / specs: https://www.msi.com/Motherboard/B550-A-PRO/Specification
- Support (BIOS, manual, memory QVL): https://www.msi.com/Motherboard/B550-A-PRO/support

> **How we got here:** the original plan was an AM5 / DDR5 ASUS B650E build. That was abandoned — the ASUS board would not POST after transplant, the build was **downgraded to AM4 / DDR4**, and this **MSI B550-A PRO** was bought locally (pawnshop). It **POSTs and runs** with the Ryzen 7 5800X + RTX 3060 Ti. This doc reflects the board we actually own.

## Identity

- **MSI B550-A PRO** — AMD **B550** chipset, socket **AM4**, **ATX**.
- Supports **Ryzen 5000 / 5000 G-series / 4000 G-series / 3000** desktop CPUs (AM4). A BIOS update was historically required for Ryzen 5000 on early B550 stock — **ours already runs a 5800X, so the BIOS is new enough**; no flash needed.
- **No onboard WiFi.** Rear I/O has **HDMI + DisplayPort**, but those outputs **only work with an APU** (G-series). The **Ryzen 7 5800X has no integrated graphics**, so video comes **only from the RTX 3060 Ti** — this is why the box would not display until the GPU was installed. See [03](03-cpu-ryzen-7-5800x.md).

## Memory support (MSI spec)

- **4 × DDR4 DIMM slots**, dual-channel (2 DIMMs per channel).
- **Max capacity: 128 GB** DDR4, **unbuffered non-ECC UDIMM only** (LRDIMM / registered server RAM will **not** POST).
- **Rated speed: up to DDR4-4400 (OC)** via A-XMP, depending on CPU/config. The **CPU officially rates DDR4-3200** ([03](03-cpu-ryzen-7-5800x.md)).
- We run **64 GB DDR4** — enough to absorb all three retiring workers ([05](05-memory-sizing-proper-path.md)).

## DDR4 speed on Zen 3 — the sweet spot

The Zen 3 (Ryzen 5000) equivalent of the DDR5-6000 rule is **DDR4-3600 CL16 at FCLK 1800 MHz**:

- At DDR4-3600 the Infinity Fabric (FCLK), memory controller (UCLK) and memory (MCLK) run **1:1:1** — the best real-world bandwidth+latency balance for Zen 3.
- Pushing past ~3733–3800 usually drops the fabric to a **2:1** ratio, adding latency that erases the gain. **Don't chase DDR4-4000+** on this platform.
- If our 64 GB kit is rated 3200, run its **A-XMP profile** and (optionally) try 3600 1:1; if it won't hold 3600, DDR4-3200 is a perfectly good stable floor.

## 4-DIMM note

If the 64 GB is **4×16** (all four slots filled) rather than 2×32, expect the achievable speed to be a bit lower than a 2-DIMM kit — four sticks load the controller harder. That's fine here: capacity, not bandwidth, is the constraint for a K8s node. If it's **2×32**, populate **DIMMA2 + DIMMB2** (slots 2 and 4 from the CPU — MSI's standard 2-DIMM fill order; verify against the board silkscreen/manual).

## Storage & expansion (MSI spec)

- **2 × M.2 slots:**
  - **M2_1 — PCIe 4.0 x4, from the CPU** (with Ryzen 5000/3000). This is the fast slot → the **1 TB NVMe boot/data drive goes here**.
  - **M2_2 — PCIe 3.0 x4, from the B550 chipset.** ⚠️ Populating M2_2 with a PCIe SSD **disables the PCI_E3 slot** (shared lanes).
- **6 × SATA 6 Gb/s** — the **2 TB Seagate mechanical HDD** connects here (SATA data + SATA power from the PSU).
- **PCIe:** one **PCIe 4.0 x16** (CPU) for the RTX 3060 Ti, plus chipset PCIe 3.0 slots.

## Networking

- **Realtek RTL8111H — Gigabit (1 GbE)** wired LAN. ⚠️ **Not** 2.5G (unlike the abandoned ASUS board). 1 Gb is fine for a K8s worker; note it if the cluster assumes 2.5G anywhere.
- No WiFi.

## Power & diagnostics

- **CPU power: single 8-pin EPS** (top-left) + the **24-pin** ATX. Seat both fully.
- **EZ Debug LEDs** (4 LEDs near the 24-pin): **CPU (red) · DRAM (yellow) · VGA (white) · BOOT (green)** — the board's only POST readout (no numeric Q-Code display). A **solid white VGA LED on a GPU-less boot = "no display source found"**, which is exactly what we saw before the 3060 Ti went in.

## BIOS / firmware

- MSI **Click BIOS 5** (UEFI). **No BIOS Flash Button** on this SKU — a BIOS update needs a working CPU installed (M-Flash from USB). Ours already boots a 5800X, so no update is required to run.
- **First-boot memory training** after a RAM change is slower than normal — expected, **not a hang**. DDR4 training is far quicker than DDR5. See [06](06-assembly-and-bios-setup.md).

## Sources

- [MSI B550-A PRO specification](https://www.msi.com/Motherboard/B550-A-PRO/Specification)
- [Amazon listing (AMD Ryzen 5000, AM4, DDR4, PCIe 4.0, SATA 6Gb/s, M.2, USB 3.2 Gen 2, HDMI/DP, ATX)](https://www.amazon.com/MSI-B550-PRO-ProSeries-Motherboard/dp/B089CZSQB4)
- [Newegg B550-A PRO](https://www.newegg.com/msi-b550-a-pro-atx-amd-motherboard-amd-b550-am4/p/N82E16813144330)
