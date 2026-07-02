#!/usr/bin/env python3
"""Red-meteor RGB animator for the compute-monster Lian Li UNI hub.

Reproduces the documented look (docs/09): a red comet ("Meteor") chasing around
the fan LEDs over a dim-red background — headless, via the OpenRGB SDK server.

Usage:
  meteor.py --list      # print detected devices + LED counts (for calibration)
  meteor.py             # run the animation loop (used by the systemd service)

Config comes from environment (see provision/config.env / meteor.conf):
  COLOR=R,G,B  TAIL=R,G,B  SPEED=0-100  BRIGHTNESS=0-100  BACKGROUND_RED=0-255
"""
import os
import sys
import time

try:
    from openrgb import OpenRGBClient
    from openrgb.utils import RGBColor
except Exception as e:  # pragma: no cover
    print(f"openrgb-python not available: {e}", file=sys.stderr)
    sys.exit(1)

HOST = os.environ.get("OPENRGB_HOST", "127.0.0.1")
PORT = int(os.environ.get("OPENRGB_PORT", "6742"))


def _triple(name, default):
    raw = os.environ.get(name, default)
    r, g, b = (int(x) for x in raw.split(","))
    return r, g, b


def _scale(rgb, brightness):
    f = max(0, min(100, brightness)) / 100.0
    return RGBColor(int(rgb[0] * f), int(rgb[1] * f), int(rgb[2] * f))


def connect(retries=30):
    last = None
    for _ in range(retries):
        try:
            return OpenRGBClient(HOST, PORT, name="compute-monster-meteor")
        except Exception as e:  # server not up yet
            last = e
            time.sleep(2)
    raise SystemExit(f"could not reach OpenRGB server {HOST}:{PORT}: {last}")


def target_devices(client):
    """Prefer Lian Li hubs; fall back to every device so it still lights up."""
    liate = [d for d in client.devices if "lian" in d.name.lower()
             or "uni" in d.name.lower()]
    return liate or list(client.devices)


def list_devices(client):
    for i, d in enumerate(client.devices):
        print(f"[{i}] {d.name!r}  type={d.type}  leds={len(d.leds)}  "
              f"zones={[ (z.name, len(z.leds)) for z in d.zones ]}")


def run():
    color = _triple("COLOR", "255,0,0")
    tail = _triple("TAIL", "255,23,19")
    speed = int(os.environ.get("SPEED", "25"))
    brightness = int(os.environ.get("BRIGHTNESS", "100"))
    bg_red = int(os.environ.get("BACKGROUND_RED", "24"))

    head = _scale(color, brightness)
    tail_c = _scale(tail, brightness)
    bg = RGBColor(bg_red, 0, 0)
    # L-Connect speed 0..100 -> per-frame delay. Higher speed = faster comet.
    delay = max(0.01, (100 - max(0, min(100, speed))) / 100.0 * 0.14 + 0.02)
    TAIL_LEN = 6

    client = connect()
    devs = target_devices(client)
    if not devs:
        raise SystemExit("no RGB devices found")
    for d in devs:
        try:
            d.set_mode("Direct")
        except Exception:
            pass  # some devices expose it differently; direct set still works
    print(f"animating meteor on: {[d.name for d in devs]}", flush=True)

    pos = [0 for _ in devs]
    while True:
        try:
            for di, d in enumerate(devs):
                n = len(d.leds)
                if n == 0:
                    continue
                frame = [bg] * n
                for t in range(TAIL_LEN):
                    idx = (pos[di] - t) % n
                    frame[idx] = head if t == 0 else tail_c
                d.set_colors(frame, fast=True)
                pos[di] = (pos[di] + 1) % n
            time.sleep(delay)
        except (BrokenPipeError, ConnectionResetError, OSError) as e:
            print(f"connection dropped ({e}); reconnecting...", file=sys.stderr)
            time.sleep(3)
            client = connect()
            devs = target_devices(client)
            for d in devs:
                try:
                    d.set_mode("Direct")
                except Exception:
                    pass
            pos = [0 for _ in devs]


if __name__ == "__main__":
    if "--list" in sys.argv:
        list_devices(connect())
    else:
        run()
