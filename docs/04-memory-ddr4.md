# 04 — Memory: 64 GB DDR4 (AM4 / Zen 3)

Official guidance: AMD (CPU memory support) + the DIMM maker's spec + the MSI B550-A PRO QVL.

## What we have

**64 GB DDR4** installed and POSTing on the MSI B550-A PRO with the Ryzen 7 5800X.

> **Confirm the exact kit** with `sudo dmidecode -t memory` (or in Click BIOS) once Linux is on: number of DIMMs, size per stick (2×32 vs 4×16), rated speed, and rank. That determines the tuning below.

## Type / compatibility rules

- Must be **DDR4 UDIMM, unbuffered, non-ECC** (or ECC-UDIMM run as non-ECC). **LRDIMM / RDIMM server memory will NOT POST** on this board — this was already flagged as the fatal flaw of one shopping option in [`am4-build-pricing.csv`](am4-build-pricing.csv).
- Board max is **128 GB** across 4 slots; CPU max is **128 GB**. 64 GB sits comfortably below both.

## Speed target (Zen 3)

- **Sweet spot: DDR4-3600 CL16, FCLK 1800 → 1:1:1** fabric/controller/memory. See [03](03-cpu-ryzen-7-5800x.md).
- If the kit is rated **3200**, enable **A-XMP** and run 3200 (rock-solid), or try nudging to 3600 1:1 and validate stability.
- **Don't chase 4000+** — the fabric drops to 2:1 and latency erases the benefit.

## Rank / DIMM-count effect

- **2×32 GB** = dual-rank, 2 DIMMs → easiest to hold a high 1:1 speed. Populate **DIMMA2 + DIMMB2** (slots 2 + 4 from the CPU).
- **4×16 GB** = all four slots filled → heavier controller loading, so the top stable speed may be a little lower (often 3200–3466 rather than 3600). **This is fine** — for a K8s node, 64 GB of capacity matters far more than the last few hundred MT/s of bandwidth.

## Do NOT mix mismatched sticks

If you ever grow capacity, add a **single matched kit** of the target size rather than pairing leftover sticks — mixed kits (even identical part numbers) risk XMP failing to enable or no-boot. Same rule that applied on the old DDR5 plan; it holds on DDR4 too.

## Why 64 GB is the right number

The three retiring workers total **~49 GiB** of RAM capacity; 64 GB beats that with comfortable burst headroom. Full reasoning in [05](05-memory-sizing-proper-path.md).
