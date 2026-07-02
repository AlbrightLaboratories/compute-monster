#!/usr/bin/env python3
"""Lian Li hub RGB diagnostic: print the hub's ACTUAL state (mode, colors,
brightness, speed), then run an unmissable visual sequence:
  Static RED (10s) -> Rainbow Wave (10s) -> native Meteor RED (final)
each at MAX brightness. Prints everything it does so CI logs show the truth.
"""
import sys
import time

from openrgb import OpenRGBClient
from openrgb.utils import RGBColor

RED = RGBColor(255, 0, 0)


def show(d):
    try:
        m = d.modes[d.active_mode]
        cols = [f"#{c.red:02X}{c.green:02X}{c.blue:02X}" for c in (m.colors or [])]
        print(f"STATE {d.name}: active={m.name!r} colors={cols} "
              f"speed={getattr(m,'speed',None)} "
              f"brightness={getattr(m,'brightness',None)} "
              f"(bmin={getattr(m,'brightness_min',None)} bmax={getattr(m,'brightness_max',None)})",
              flush=True)
    except Exception as e:
        print(f"STATE {d.name}: unreadable: {e}", flush=True)


def set_native(d, mode_name, colors=None, speed_pct=None):
    m = next((x for x in d.modes if x.name.lower() == mode_name.lower()), None)
    if m is None:
        print(f"{d.name}: mode {mode_name!r} not found", flush=True)
        return False
    try:
        if colors is not None:
            n = getattr(m, "colors_max", None) or len(colors)
            m.colors = (colors * n)[:n]
    except Exception as e:
        print(f"{d.name}: {mode_name} colors err: {e}", flush=True)
    try:
        bmax = getattr(m, "brightness_max", None)
        if bmax:
            m.brightness = bmax
    except Exception as e:
        print(f"{d.name}: {mode_name} brightness err: {e}", flush=True)
    try:
        smax = getattr(m, "speed_max", None)
        smin = getattr(m, "speed_min", None) or 0
        if smax is not None and speed_pct is not None:
            m.speed = smin + int((smax - smin) * speed_pct / 100)
    except Exception as e:
        print(f"{d.name}: {mode_name} speed err: {e}", flush=True)
    try:
        d.set_mode(m)
        print(f"SET {d.name}: {mode_name} applied "
              f"(colors={'RED' if colors else 'default'}, brightness=max)", flush=True)
        return True
    except Exception as e:
        print(f"SET {d.name}: {mode_name} FAILED: {e}", flush=True)
        return False


def main():
    client = OpenRGBClient("127.0.0.1", 6742, name="cm-rgb-diag")
    hubs = [d for d in client.devices
            if "lian" in d.name.lower() or "uni" in d.name.lower()]
    if not hubs:
        print("NO LIAN LI HUB FOUND on server", flush=True)
        sys.exit(1)
    for d in hubs:
        print(f"=== {d.name}: {len(d.leds)} leds, zones="
              f"{[(z.name, len(z.leds)) for z in d.zones]}", flush=True)
        show(d)
        print("--- TEST 1: Static RED 10s ---", flush=True)
        set_native(d, "Static", [RED])
        show(d)
        time.sleep(10)
        print("--- TEST 2: Rainbow Wave 10s ---", flush=True)
        set_native(d, "Rainbow Wave", None, speed_pct=60)
        show(d)
        time.sleep(10)
        print("--- FINAL: native Meteor RED ---", flush=True)
        set_native(d, "Meteor", [RED], speed_pct=25)
        show(d)
    print("diag complete", flush=True)


if __name__ == "__main__":
    main()
