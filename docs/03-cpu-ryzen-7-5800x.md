# 03 — CPU: AMD Ryzen 7 5800X

Official source of truth: AMD.

- Product page: https://www.amd.com/en/products/processors/desktops/ryzen/5000-series/amd-ryzen-7-5800x.html
- Spec DB: https://www.amd.com/en/product/10683

## Specs (verbatim from AMD)

| Spec | Value |
|------|-------|
| Architecture | **Zen 3** (Vermeer) |
| Cores / threads | **8 / 16** |
| Base / boost clock | **3.8 GHz / up to 4.7 GHz** |
| Cache (L2 + L3) | 4 MB + 32 MB = **36 MB** |
| Default TDP | **105 W** (max PPT ~142 W) |
| Socket | **AM4** |
| Tjmax (max temp) | **90 °C** (normal operating ceiling) |
| Boost / OC | Precision Boost 2, **PBO** + Curve Optimizer, unlocked |
| iGPU | **None — discrete GPU required.** No onboard graphics; the board's HDMI/DP stay dark with this chip. |
| PCIe | **PCIe 4.0**, 24 usable CPU lanes (+ chipset lanes from B550) |

## Official memory support (AMD)

- Type: **DDR4** UDIMM, dual-channel
- **Max capacity: 128 GB**
- ECC: yes (needs board support; MSI B550-A PRO is non-ECC)
- **Official rated (JEDEC) speed: DDR4-3200.** Anything above 3200 is, by AMD's definition, **memory overclocking** (A-XMP is the supported one-click path).

## The DDR4-3600 sweet spot — proper path vs workaround

Zen 3's memory sweet spot is **DDR4-3600 CL16 with FCLK at 1800 MHz**:

- **Proper path:** a 3600-rated kit (or 3200 kit tuned to 3600), A-XMP on, **FCLK 1800** → Infinity Fabric : memory controller : memory all run **1:1:1**. Best bandwidth+latency balance for Zen 3.
- **Workaround / diminishing returns:** pushing past ~3733–3800 forces the fabric to **2:1**, adding latency that usually erases the gain — faster kits often benchmark *worse*. Holding 1:1 above 3800 needs silicon luck + hand-tuning.

**Bottom line:** target DDR4-3600 1:1 if the kit supports it; DDR4-3200 is a fine stable floor. See [05](05-memory-sizing-proper-path.md).

## Why the box wouldn't display before the GPU

The 5800X is **not** an APU — it has **zero integrated graphics**. On a GPU-less boot the MSI board lit its **white VGA EZ Debug LED** ("no display source"). The board was POSTing fine; it simply had nothing to draw video with. Installing the **RTX 3060 Ti** gave it a display output and the box came up. This is the single most important gotcha of this CPU choice: it **always needs a discrete GPU**.

## Thermals & cooler

- **105 W part that runs hot** — the 5800X is known for high thermal density (single CCD) and will happily sit near its **90 °C** ceiling under sustained all-core load even on strong coolers. That's normal for this chip, not a fault.
- We cool it with an **AIO liquid cooler** — the right match for a hot 105 W chip and quieter than air under sustained load. **Mount the radiator ABOVE the CPU/pump** (top-mount) or **front-mount with the tubes at the bottom**, so trapped air collects in the radiator and never in the pump. See [08](08-case-and-fan-placement.md).
- Validate under load: temps should stabilize **below 90 °C**; brief touches of 90 °C under an all-core stress test are expected and safe (the chip throttles, it doesn't fail).
