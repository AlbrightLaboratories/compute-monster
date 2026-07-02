# 08 — Case, AIO cooler + fan placement, and RGB lighting

## Owned (current state)

| Item | Qty | Notes |
|------|----:|-------|
| **KEDIERS K4 (MAX)** ATX dual-chamber case | 1 | ASIN `B0FD382Y92`. Full-view dual tempered glass (front+side), BTF. **420 mm radiator** capable, up to ~10–11×120 mm fans, **175 mm** cooler height, ~**400 mm** GPU, 200 mm PSU. |
| **AIO liquid CPU cooler** (radiator + pump) | 1 | Cools the hot 105 W **Ryzen 7 5800X** ([03](03-cpu-ryzen-7-5800x.md)). **Mount radiator ABOVE the pump** — see rule below. |
| Lian Li **UNI FAN SL-Infinity 120** ARGB | (owned) | The showcase fans — daisy-chain, interlocking LED strip. Used for the RGB "chasing" effect below. |
| Lian Li **UNI FAN SL-INF 140 Reverse Blade** ARGB | (owned) | Intake hero fans where 140 mm mounts exist. |
| Lian Li **UNI controller** | 1 | 4 ports × up to 4 fans = 16 max. |
| **RTX 3060 Ti** GPU | 1 | ~200 W, ~2-slot; fits easily (400 mm GPU clearance). The **only video source** on this CPU. |

---

## AIO radiator mounting — the "air can't sit in the pump" rule

Air bubbles rise; you never want them collecting in the pump. So the **radiator must sit higher than the pump/CPU block**:

1. **Top-mount (radiator on top, as exhaust) — best here.** Radiator is the highest point → any air pools harmlessly in it, and warm liquid heat exhausts straight up out of the case. This also **keeps the showcase side glass free** for the UNI intake wall. **Recommended.**
2. **Front/side-mount with the tubes entering at the BOTTOM** — also fine; tubes-at-bottom keeps the pump below the air line.
3. ❌ **Any mount where the pump is the highest point**, or a front/side rad with **tubes at the top** — avoid (gurgle, poor flow, early pump death).

Set the pump to **100% / full-speed PWM** on a `PUMP_FAN` (or `CPU_FAN`) header — pumps aren't temperature-throttled like fans.

---

## Fan placement (dual-chamber = side/bottom intake → top/rear exhaust)

This case doesn't do front-to-back airflow. With the **AIO radiator on top (exhaust)**:

| Location | Fans | Direction | Why |
|----------|------|-----------|-----|
| **Top** | AIO radiator fans | **Exhaust** | Radiator is highest point (pump rule) + dumps heat up. |
| **Side wall** (glass-facing) | UNI SL-Infinity as **intake** | **Intake** | The showcase wall — infinity LEDs face the viewer while feeding cool air in. |
| **Bottom** | UNI fans as **intake** | **Intake** | Feeds the RTX 3060 Ti; visible through lower glass. |
| **Rear** | 1× UNI fan | **Exhaust** | Pulls residual case heat out. |

Aim for **more intake than exhaust → slight positive pressure** = less dust through the glass-adjacent intakes. Good for a 24/7 box.

- A **120 mm** fan screws at **105 mm** spacing; a **140 mm** at **124.5 mm** — check each mount's slot spacing to see which of the 140-reverse fans actually bolt in. Anything that doesn't fit stays a spare; don't force a 140 into a 120 mount.

---

## RGB LIGHTING — set colors, the "chasing" flow effect, and keep it under Linux

This answers three things: **(1) how to set the colors, (2) how to get the single light that runs the full length side→middle→right across the fans, and (3) how to keep it after you wipe Windows for Linux.**

### The key fact — and the persistence gotcha
Lian Li's **L-Connect 3 app is Windows-only** — there is no official Linux app.

⚠️ **A custom effect built in L-Connect is driven LIVE by the app and does NOT reliably persist.** On this build the lighting **resets to the default rainbow on every reboot** — proof that the effect lives only in software (or is on "Motherboard sync"), not committed to the controller's onboard memory. **If you wipe Windows in that state, you lose the look.**

So lighting on a Windows-free box has to be driven by something that runs without Windows. Two reliable paths:
- **Controller hardware button** — cycles **onboard effects stored in the controller ROM**; these survive reboot *and* full power-off with zero software. Limited to built-in effects (may not match a custom merged-chase). **Test: pick one, reboot, confirm it holds — before wiping.**
- **OpenRGB on Linux** — partial UNI support; can re-apply colors/effect at boot via a systemd service. Closest to a custom look on a Windows-free node; test it, support varies by controller revision.

**Prove persistence before wiping:** close L-Connect (or disable its autostart), reboot, and watch the fans. If they go default, the profile was never saved — use the hardware button or OpenRGB. ([06](06-assembly-and-bios-setup.md) covers the wipe/Linux install.)

### 1 — Set the colors (do this while Windows is still installed)
1. Install **L-Connect 3** from Lian Li.
2. It detects the controller and each fan. Select a fan/zone → pick a **static color** or a color-cycling effect, set brightness. Apply.

### 2 — The "chasing" effect that flows the whole length (side → middle → right)
That demo is a **flowing/marquee effect running across one continuous LED strip**. Two requirements:

- **Wiring:** the fans you want the light to sweep across must be **interlocked in ONE daisy-chain on ONE controller port** (same fan size per chain — don't mix 120 + 140 on one chain). Put the **side → middle → right** fans on the **same port** so their LEDs form one continuous run. Fans split across different ports restart the effect per group (you'd see it repeat, not travel the full length).
- **In L-Connect 3:** select those fans and **"Merge"** them into a **single lighting zone** so effects treat the whole chain as one surface instead of per-fan. Then choose a **flowing effect** — the ones that "run" fan-to-fan are **Runway, Meteor, Neon, Stack, or Rainbow Morph** — and set the **direction** so the light travels the way you want. Tune speed/color/brightness. Apply.
- Merged + one chain + a directional flow effect = the single line that appears to travel the entire length across all the fans.

### 3 — Keep it after removing Windows → Linux
- ⚠️ **A custom L-Connect effect usually will NOT survive the wipe** (see the persistence gotcha above — this build resets to rainbow on reboot). Get lighting into a Windows-free state and **prove it holds through a reboot before wiping**: use the **controller hardware button** (onboard effects, guaranteed persistent) or plan to reproduce it with **OpenRGB on Linux**.
- On Linux:
  - **Fan SPEED** is controlled by the **motherboard PWM header** the controller's 4-pin plugs into → set it via the **MSI BIOS fan curve** or Linux **`fancontrol`/`lm-sensors`** (`pwmconfig`). This is the only part that matters for a compute node.
  - **Lighting** stays as last set. To change it later without Windows: use the **hardware button on the controller** (cycles presets + sync), or try **OpenRGB** (community, *partial* UNI support — test it, not guaranteed). Otherwise a one-off Windows session (or a spare Windows drive) to re-program.
- **Never make RGB a runtime dependency of the node.** Lighting is set-and-forget; speed is BIOS/`fancontrol`.

### Controller wiring recap
- **PWM/speed:** one 4-pin from the controller → a motherboard `SYS_FAN`/`CPU_FAN` header.
- **Data/ARGB:** one internal **USB 2.0** header (for L-Connect 3 while on Windows).
- **Power:** **SATA** from the PSU to the controller (it powers the fans, not the headers).
- Keep each daisy-chain a single fan size; different ports may be different sizes and are independently programmable.

---

## Sources

- KEDIERS K4 MAX — [Amazon `B0FD382Y92`](https://www.amazon.com/KEDIERS-Pre-Installed-Computer-Full-View-K4/dp/B0FD382Y92) · [manual](https://manuals.plus/asin/B0FD382Y92)
- Lian Li — [UNI FAN SL-Infinity](https://lian-li.com/product/uni-fan-sl-infinity/) · [L-Connect 3](https://lian-li.com/l-connect-3/)
