#!/usr/bin/env python3
"""Brightness-inversion test for the Lian Li hub.

Suspicion: OpenRGB brightness on this hub is INVERTED (0=bright, 4=off), so
every earlier "brightness=max(4)" set was actually OFF.

Sequence (watch the fans, especially the TOP TWO):
  Static RED  @ brightness 0   — 20s   <- if inverted, THIS lights
  Static RED  @ brightness 2   — 20s
  Static RED  @ brightness 4   — 20s   <- if normal, THIS lights
  Meteor RED  @ whichever... final left at brightness 0 AND printed
Prints wall-clock segments so the operator's report maps to a value.
"""
import time

from openrgb import OpenRGBClient
from openrgb.utils import RGBColor

RED = RGBColor(255, 0, 0)


def set_mode(d, name, colors, brightness, speed_pct=None):
    m = next((x for x in d.modes if x.name.lower() == name.lower()), None)
    if m is None:
        print(f"mode {name} missing", flush=True)
        return
    try:
        if colors is not None:
            n = getattr(m, "colors_max", None) or len(colors)
            m.colors = (colors * n)[:n]
    except Exception as e:
        print(f"colors err: {e}", flush=True)
    try:
        m.brightness = brightness
    except Exception as e:
        print(f"brightness err: {e}", flush=True)
    try:
        smax = getattr(m, "speed_max", None)
        if smax is not None and speed_pct is not None:
            smin = m.speed_min or 0
            m.speed = smin + int((smax - smin) * speed_pct / 100)
    except Exception:
        pass
    d.set_mode(m)
    print(f"{time.strftime('%H:%M:%S')}  {name} RED brightness={brightness}", flush=True)


def main():
    client = OpenRGBClient("127.0.0.1", 6742, name="cm-diag2")
    hubs = [d for d in client.devices if "lian" in d.name.lower()
            or "uni" in d.name.lower()]
    if not hubs:
        raise SystemExit("no hub")
    d = hubs[0]
    print(f"target: {d.name}", flush=True)
    for b in (0, 2, 4):
        set_mode(d, "Static", [RED], b)
        time.sleep(20)
    # Leave it on Meteor red at brightness 0 (the inverted-max candidate).
    set_mode(d, "Meteor", [RED], 0, speed_pct=25)
    print("diag2 complete — final: Meteor RED brightness=0", flush=True)


if __name__ == "__main__":
    main()
