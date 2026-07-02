# 01 — Bill of materials (as built)

The compute-monster is **built and POSTing** as an **AM4 / DDR4** box. This replaces the earlier AM5/DDR5 *shopping plan* — that ASUS B650E build was abandoned after it wouldn't POST; the machine was downgraded to AM4 and assembled from locally-bought (pawnshop) + on-hand parts.

## Owned & installed (verified working)

| Component | Product | Key spec | Source |
|-----------|---------|----------|--------|
| Motherboard | MSI **B550-A PRO** | AMD B550, **AM4**, ATX, 4×DDR4, 2×M.2, 6×SATA, 1 GbE, no WiFi | [MSI](https://www.msi.com/Motherboard/B550-A-PRO/Specification) · [02](02-motherboard-msi-b550-a-pro.md) |
| CPU | AMD **Ryzen 7 5800X** | Zen 3, **8C/16T**, 3.8/4.7 GHz, 105 W, **no iGPU** | [AMD](https://www.amd.com/en/products/processors/desktops/ryzen/5000-series/amd-ryzen-7-5800x.html) · [03](03-cpu-ryzen-7-5800x.md) |
| CPU cooler | **AIO liquid cooler** (radiator + pump) | For the hot 105 W chip; **radiator mounted above the pump** | [08](08-case-and-fan-placement.md) |
| Memory | **64 GB DDR4** (UDIMM) | Absorbs the 3 retiring workers (~49 GiB); run A-XMP → DDR4-3600 1:1 if kit allows | [04](04-memory-ddr4.md) · [05](05-memory-sizing-proper-path.md) |
| GPU | NVIDIA **RTX 3060 Ti** | 8 GB, ~200 W; **the only video source** on this CPU + usable for light ML/inference | — |
| Boot/data SSD | **1 TB NVMe** | In **M2_1** (PCIe 4.0 x4, CPU) | [02](02-motherboard-msi-b550-a-pro.md) |
| Bulk storage | **2 TB Seagate** mechanical HDD | On a **SATA** port; mount as `/data` | [06](06-assembly-and-bios-setup.md) |
| PSU | (installed — confirm model/wattage) | Must cover ~350–400 W load; 550 W+ quality unit is plenty | see PSU note |
| Case | KEDIERS **K4 (MAX)** ATX dual-chamber | 420 mm rad, 175 mm cooler, ~400 mm GPU, full glass | [08](08-case-and-fan-placement.md) |
| Case fans / lighting | Lian Li **UNI FAN SL-Infinity 120** + **SL-INF 140 Reverse** + **UNI controller** | Showcase RGB; set colors/effects in Windows, persists under Linux | [08](08-case-and-fan-placement.md) |

## Nothing left to buy for it to run

Unlike the old AM5 plan (which had PSU/NVMe/GPU as gaps), **this build is complete**: it POSTs, has a GPU, boot NVMe, bulk HDD, 64 GB RAM, and cooling. Remaining work is **software**, not hardware — wipe Windows → install Linux → join the cluster ([06](06-assembly-and-bios-setup.md)).

## Part notes

### CPU has no integrated graphics
The 5800X is **not** an APU — the board's HDMI/DP are dead with it. **A discrete GPU is mandatory**, which is why the box only displayed after the **RTX 3060 Ti** went in. Keep the monitor cable on the **card**, not the motherboard. ([03](03-cpu-ryzen-7-5800x.md))

### Memory
64 GB DDR4 beats the ~49 GiB of the three retiring workers with headroom. Enable **A-XMP** and target **DDR4-3600 1:1** (FCLK 1800); DDR4-3200 is a fine floor. Confirm sticks are **UDIMM non-ECC** — LRDIMM/RDIMM won't POST. ([04](04-memory-ddr4.md) / [05](05-memory-sizing-proper-path.md))

### Storage
- **1 TB NVMe → M2_1** (PCIe 4.0 x4 off the CPU) — the fast slot, boot + hot data.
- **2 TB Seagate → SATA** — bulk/cold data. ⚠️ If you ever add a 2nd NVMe in **M2_2**, the **PCI_E3** slot is disabled (shared chipset lanes). ([02](02-motherboard-msi-b550-a-pro.md))

### PSU note
The system peaks around **350–400 W** (5800X ~140 W PPT + RTX 3060 Ti ~200 W + rest). A quality **550–650 W 80+ Gold** unit is ample. **Confirm the installed PSU's model/wattage and that it has the PCIe power the 3060 Ti needs** (1× or 2× 8-pin depending on the card). If it's an unknown/no-name unit, plan to replace it — the PSU is the one part that can take the board/CPU/GPU with it.

### Cooler — AIO mounting
Mount the **radiator above the pump** (top-mount preferred, or front/side with tubes at the bottom) so air can't pool in the pump. Set the pump header to full speed. ([03](03-cpu-ryzen-7-5800x.md) / [08](08-case-and-fan-placement.md))

## Historical: the abandoned AM4 shopping list

An earlier eBay-sourcing pass is preserved in [`am4-build-pricing.csv`](am4-build-pricing.csv) (ASUS X570-E + 5900X + assorted RAM). It was **not** the path taken — the actual box is the MSI B550-A PRO + 5800X above. Kept only as a record of the LRDIMM-won't-POST lesson.
