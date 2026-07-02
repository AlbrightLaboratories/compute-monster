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

    # We don't know which of the hub's 8 channels the 4 fan groups are cabled to
    # (only Channel 1 accepted a guessed resize), so size EVERY channel to full
    # capacity — empty ports stay dark, populated ones light. Trim later.
    LEDS_PER_FAN = int(os.environ.get("LEDS_PER_FAN", "40"))
    MAX_FANS_PER_CHANNEL = int(os.environ.get("MAX_FANS_PER_CHANNEL", "4"))
    CHANNEL_WANT = LEDS_PER_FAN * MAX_FANS_PER_CHANNEL

    def prep(d):
        """Direct mode + resize resizable zones (Lian Li hub channels default to
        0 LEDs until told how many fans are chained — leaving them 0 means the
        animator runs happily while the fans stay dark)."""
        try:
            d.set_mode("Direct")
        except Exception:
            pass
        resized = False
        for zi, z in enumerate(d.zones):
            zmax = getattr(z, "leds_max", 0) or 0
            zmin = getattr(z, "leds_min", 0)
            print(f"zone[{zi}] {z.name!r}: leds={len(z.leds)} min={zmin} max={zmax}",
                  flush=True)
            want = zmax or CHANNEL_WANT
            try:
                if want and len(z.leds) < want:
                    z.resize(want)
                    resized = True
                    print(f"zone[{zi}] resized -> {want}", flush=True)
            except Exception as e:
                print(f"zone resize failed ({d.name}/{z.name} -> {want}): {e}",
                      flush=True)
        return resized

    # Resize → reconnect until stable: each channel's resize only shows up in a
    # fresh controller read, and channels can land on different rounds.
    for _ in range(4):
        if not any(prep(d) for d in devs):
            break
        time.sleep(2)
        client = connect()
        devs = target_devices(client)
    print(f"animating meteor on: {[(d.name, len(d.leds)) for d in devs]}", flush=True)
    if all(len(d.leds) == 0 for d in devs):
        raise SystemExit("target devices have 0 LEDs after resize — check hub zones")

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
