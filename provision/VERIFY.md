# compute-monster — post-boot verification checklist

Run these after the restore USB has installed and the box has rebooted at least
once (give the first-boot service a few minutes — it installs the NVIDIA driver
and reboots). SSH in as `a_guy` or use the console.

Quick all-in-one (prints PASS/FAIL per component):
```sh
sudo bash /opt/compute-monster-provision/VERIFY.sh
```
The sections below are the source of truth / manual fallback for each check.

---

## 0. First-boot provisioning actually ran
```sh
ls -l /var/lib/compute-monster-provisioned          # exists = bootstrap completed
systemctl status compute-monster-firstboot --no-pager
journalctl -u compute-monster-firstboot --no-pager | tail -40
ls -l /opt/compute-monster-provision/log/           # per-step logs
```
✅ Expect: the marker file present, service `active (exited)`, no step marked FAILED.

## 1. Identity / OS (steps/10)
```sh
hostnamectl | grep -E "hostname|Operating System"   # compute-monster, Ubuntu 24.04
timedatectl | grep -E "Time zone"                   # America/New_York
whoami                                               # a_guy
```

## 2. NVIDIA / RTX 3060 Ti (steps/20)
```sh
nvidia-smi                                           # lists "RTX 3060 Ti", driver + CUDA
lspci | grep -i nvidia
```
✅ Expect: `nvidia-smi` prints the GPU table (not "command not found" / "no devices").
If it errors right after install, reboot once more (driver needs a clean boot).

## 3. Storage — 2 TB Seagate at /data (steps/30)
```sh
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT                 # NVMe = /, Seagate ~2T = /data
df -h /data
grep data /etc/fstab                                 # UUID= ... /data ext4 ... (persistent)
touch /data/.write-test && rm /data/.write-test && echo "data writable"
```
✅ Expect: `/data` mounted, writable, and in fstab (survives reboot).

## 4. RGB — red meteor (steps/40)
```sh
systemctl status openrgb-server openrgb-meteor --no-pager
journalctl -u openrgb-meteor --no-pager | tail -20   # "animating meteor on: [...]"
```
- ✅ **Fans show the red chasing meteor** = done.
- ❌ Log says no devices / not animating → OpenRGB didn't detect the hub:
  ```sh
  /opt/openrgb-meteor/venv/bin/python /opt/openrgb-meteor/meteor.py --list
  ```
  Note the device index + LED count, then (if needed) tweak `/opt/openrgb-meteor/meteor.conf`
  and `sudo systemctl restart openrgb-meteor`. See `../docs/09-rgb-and-fan-profile.md`.

## 5. Fan control (steps/50)
```sh
sensors | grep -iE "fan|Tctl|Tccd" | head           # nct6775 + CPU temps visible
```
- ✅ CPU temps + fan RPMs reported.
- Bind the StandardSpeed curve if you want Linux-driven fans: `sudo pwmconfig` then
  `sudo systemctl enable --now fancontrol` — or set the curve in MSI BIOS instead.

## 6. Wake-on-LAN (steps/60)
```sh
NIC=$(ip -o route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++)if($i=="dev")print $(i+1)}')
sudo ethtool "$NIC" | grep -i "Wake-on"              # want: Wake-on: g
systemctl is-enabled "wol@${NIC}.service"
ip -o link show "$NIC" | awk '{print $2, $(NF-2)}'   # note the MAC for wakeonlan
```
✅ Expect: `Wake-on: g`, service enabled. Confirm BIOS has **Resume By PCI-E Device =
Enabled** and **ErP Ready = Disabled** (docs/06).

## 7. Kubernetes prerequisites (steps/70)
```sh
swapon --show                                        # empty = swap off ✅
systemctl status containerd --no-pager | grep Active # active (running)
kubeadm version -o short; kubelet --version; kubectl version --client -o yaml | grep gitVersion
grep -r max-pods /etc/systemd/system/kubelet.service.d/   # --max-pods=160
lsmod | grep -E "overlay|br_netfilter"
```
✅ Expect: swap off, containerd running, kube tools at the target minor, max-pods drop-in present.

### Then — the one manual step (needs a live cluster token)
On the control plane: `kubeadm token create --print-join-command`, then on this box:
```sh
sudo kubeadm join <API>:6443 --token <t> --discovery-token-ca-cert-hash sha256:<h>
kubectl get nodes            # (from the control plane) compute-monster = Ready
```

---

## Green definition
Sections 0–7 pass and the fans run the red meteor → the box is fully provisioned.
Only the `kubeadm join` remains, and that's intentionally manual.
