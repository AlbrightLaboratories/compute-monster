# compute-monster provisioning — CHANGELOG

The control record for the build-out loop. Read the status tags:

- 🔧 **on-main** — fix is in the repo `main`; the box **pulls it automatically** on the next
  provision run (`firstboot.sh` self-heals). Not yet proven on hardware.
- 🧪 **tested** — verified working on the actual box.
- 📀 **baked** — included in a cut ISO image (offline fallback + fresh-install default).

## The loop

1. We fix something → it lands on `main` (🔧). The box pulls + applies it on re-run.
2. You confirm it works on the box → mark 🧪.
3. You say **"add that to the iso"** → the item is queued for the next image.
4. You say **re-image** → `build-iso.sh` cuts a new ISO from `main`, we log an **ISO image**
   entry listing everything 📀 in it, then `flash-usb.sh` writes the USB for a clean install.

Because the ISO pulls `main` at boot, a fresh install already gets the latest 🔧 fixes;
re-imaging mainly refreshes the **offline fallback** and pins a known-good baseline.

---

## Unreleased — on `main` (pulled live by the box)

### 2026-07-02 — root-cause fix for the failed first install
- 🔧 **Resumable, fault-tolerant, reboot-aware bootstrap.** A single failing step no longer
  aborts the whole run (was `set -e`); steps record `/var/lib/compute-monster/steps/<n>.done`
  and are skipped on re-run. Fixes: "one step failed → RGB/storage/WOL/k8s all skipped."
- 🔧 **NVIDIA step reboot-aware.** Installs the driver, **blacklists nouveau**, and requests a
  reboot (exit 75) to activate — then resumes and continues. Fixes: "GPU bound to nouveau,
  nvidia-smi failed, bootstrap died."
- 🔧 **Self-healing repo pull.** `firstboot.sh` clones/pulls this repo on each boot and runs
  the latest scripts (baked copy = offline fallback), via `compute-monster-provision.service`
  that runs until `/var/lib/compute-monster/provisioned` exists.
- 🔧 **CI loop.** `provision-verify` workflow + `register-runner.sh` so provisioning can be
  dispatched and its results read remotely instead of copy-paste.

---

## ISO images

### image-001 — 2026-07-02  (❌ superseded)
- 📀 Ubuntu 24.04.4 unattended autoinstall; user `a_guy`, tz America/New_York; wipes NVMe only.
- 📀 Baked provision bundle + first-boot service (original fragile version).
- **Result:** install OK, but provisioning aborted on the NVIDIA/nouveau step; RGB never ran.
- **Superseded by** the Unreleased fixes above — do not reuse; re-image after fixes are 🧪.
