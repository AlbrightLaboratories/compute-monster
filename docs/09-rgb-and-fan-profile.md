# 09 — Decoded RGB + fan-speed profile (from L-Connect export)

Decoded from `L-Connect_LightingFanSpeed_20260701.zip` (L-Connect 3 v2.1.23.0, exported 2026-07-01). The export is a JSON wrapper whose `Data` field is base64-encoded JSON. This doc records the **actual** settings so they can be reproduced on Linux (OpenRGB / `fancontrol`) — the export itself only re-imports into L-Connect on Windows.

## Controller

- Lian Li UNI hub — USB **VID `0x0CF2`**, **PID `0xA102`** (the ID OpenRGB must match).
- **4 fan groups, 11 fans total.** SL-Infinity fans have **two independent LED rings** (Inner + Outer), set separately (`IsIndividualMode = true`).

| Group | Fans |
|-------|-----:|
| top | 2 |
| Back | 3 |
| right | 3 |
| dawn | 3 |

## Lighting — the look is all RED

Every group uses the **same scheme**:

| Ring | Effect | Colors | Brightness |
|------|--------|--------|-----------|
| **Inner** | **Door** | solid red `#FF0000` | 100 |
| **Outer** | **Meteor** (the "chasing" comet) | red `#FF0000` → `#DD1713` | 100 |

- The flowing/chasing effect the build was designed around = **Meteor** on the outer ring.
- Outer Meteor **speed = 25**; **direction** varies per group (top/right/dawn = 0, Back = 1).
- Inner Door speed differs per group (top 75, Back 25, right 0, dawn 75) but is a solid red so speed is barely visible.

> **Persistence reality:** Meteor is an *animated* effect. Keeping it alive needs something driving the LEDs continuously — on Windows that was L-Connect (which is why it reset to default on reboot). On Linux, run **OpenRGB as a systemd service** (its effect engine animates a meteor), or accept a **static red** (a one-shot OpenRGB apply at boot — no running process, rock-solid). For a 24/7 compute node, static red is the low-risk choice; the animated meteor is the wow choice that costs a small always-running service. See [08](08-case-and-fan-placement.md).

## Fan-speed curves (per 120 mm fan, tied to CPU temp)

Active RPM mode in the export ≈ **StandardSpeed**. All groups share these curves (min 210 / max 2100 RPM):

| Profile | 25 °C | 40–45 °C | 55–65 °C | 70–80 °C | 85–90 °C |
|---------|------:|---------:|---------:|---------:|---------:|
| Quiet | 420 | 945 | 1092 | 1575 | 2100 |
| **StandardSpeed** | 420 | 1050 | 1302 | 1575 | 2100 |
| HighSpeed | 945 | 1155 | 1470 | 1785 | 2100 |
| FullSpeed | 2100 | 2100 | 2100 | 2100 | 2100 |

On Linux these fans are driven by the motherboard PWM header the controller plugs into — recreate a curve like **StandardSpeed** via the MSI BIOS fan curve or `fancontrol`/`pwmconfig`. ([06](06-assembly-and-bios-setup.md) / [08](08-case-and-fan-placement.md))

## To reproduce on Linux

1. Live-USB test first: run OpenRGB, confirm it detects VID `0x0CF2` / PID `0xA102`.
2. If detected: set inner+outer to the colors above. For the meteor, use OpenRGB's effect engine (or a script) and install it as a **systemd service** so it starts headless at boot.
3. Fan speed: BIOS curve or `fancontrol` mirroring StandardSpeed.
4. **Prove it survives a reboot before wiping Windows.**
