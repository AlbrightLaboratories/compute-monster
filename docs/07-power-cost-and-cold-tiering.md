# 07 — Power cost & cold-tiering plan (Kissimmee, FL)

Researched plan for cutting electricity cost across the cluster: what stays hot, what can go cold + WOL, what gets retired, and the order to do it in. All cost math uses the **Kissimmee Utility Authority (KUA)** effective residential rate.

> **Location fixed:** the lab is in **Kissimmee, Florida** (KUA), not Hawaii. KUA effective rate ≈ **$0.1443/kWh** (energy charge ~13.4¢ + fuel/COPCA + $10.17 customer charge; FL state avg ~15¢ as cross-check). Sources: [KUA tariff](https://kua.com/electric-rates-service-fees-and-procedures/), [EIA FL](https://www.eia.gov/state/data.php?sid=FL).

## Cost of running 24/7 at KUA rate

`kWh/yr = W × 8.76` · `$/yr = kWh/yr × $0.1443`

| Continuous load | kWh/yr | $/yr |
|---:|---:|---:|
| 25 W | 219 | $32 |
| 50 W | 438 | $63 |
| 100 W | 876 | $126 |
| 240 W | 2,102 | $303 |
| 400 W | 3,504 | $506 |
| 600 W | 5,256 | $758 |

At Florida rates the savings per low-wattage box are modest (~$63/yr per 50 W device). **The big electric lever is the GPU, not the old boxes** — see §3.

## Current cluster (what runs where)

| Node | HW | CPU/RAM | Status | Carries | Verdict |
|------|----|---------|--------|---------|---------|
| k8-master | — | 4 / 30 GiB | hot | control-plane | **Stay hot** |
| k8-worker | — | 2 / 32 GiB | hot | ingress-nginx, arc-system, trading | **Stay hot** |
| kubeadm-worker02 | — | 2 / 16 GiB | hot | data-worker, ingress-nginx, trading | **Stay hot** |
| kubeadm-worker03 | — | 6 / 24 GiB | hot | corey-coder, brightflow, triton, web | **Stay hot** |
| kubeadm-worker05 | — | 8 / 24 GiB | hot | trading + **9 arc-runners** + triton | **Stay hot** (CI workhorse) |
| **daxxon-ai-gpu-01** | RTX 5090 | 32 / 64 GiB | hot | live trading, triton, AI 24/7 | **Stay hot — but power-cap GPU (§3)** |
| **corey-coder-gx10** | DGX Spark (GB10) | 20 / 125 GiB | **cordoned** | only `spark-vllm` (1 pod) | **★ Cold candidate (§1)** |
| **kubeadm-worker04** | Mac Pro 2013 VM | 4 / 24 GiB | hot | trading, corey-coder, brightflow, runners | **Retire → compute-monster (§4)** |
| **kubeadm-worker06** | Mac Pro 2013 VM | 4 / 16 GiB | hot | trading, corey-coder, brightflow, runners | **Retire → compute-monster (§4)** |
| **kubeadm-worker07** | Mac Pro 2013 VM | 3 / 10 GiB | hot | 35 trading pods, corey-coder, brightflow | **Retire → compute-monster (§4)** |

## What can go cold — three tiers

### 1. ★ corey-coder-gx10 (DGX Spark) — best immediate cold candidate
- **Already cordoned** (`unschedulable=true`) and nearly empty: the only real workload is **one** pod, `spark-vllm` (an LLM inference server). Everything else is daemonsets.
- Power: ~**25 W idle → 240 W peak** ([NVIDIA](https://docs.nvidia.com/dgx/dgx-spark/hardware.html)). Held cold vs. running ≈ **$200–270/yr** saved if it's otherwise sitting idle.
- **Plan:** if `spark-vllm` isn't needed 24/7 (it's an inference endpoint, not a latency-critical service), scale that deployment to zero or relocate it, fully drain the node, **power off**, and **WOL-wake on demand** for batch LLM/finetune work.
- **Caveat (from CLAUDE.md hard-won lessons):** the Spark is fragile and model load is **slow (~45 min UVM migration)**. So treat it as a cold spare for **non-interactive / batch** LLM work — a cold start is not instant. Power-cycle/WOL it carefully; never bare-`docker run` serve on it.

### 2. CI runners (arc-runners) — bursty by design, node-level cold spare
- GitHub Actions runners (ARC) already **scale runner pods to zero** when no CI is queued (live counts vary: 9 on worker-05, 2–3 elsewhere). The *work* is inherently bursty.
- They can't make their current nodes cold because those nodes also run trading. The opportunity: **consolidate burst CI onto one dedicated node** (the new compute-monster, or a held Mac Pro) and **WOL-wake that node only when CI demand exceeds always-hot capacity**, drain + power off when the queue drains.
- Savings are duty-cycle dependent: a runner node off 20 h/day ≈ ~80% of its idle cost avoided.

### 3. Mac Pro 2013 hosts — retire, don't cold-spare
- worker-04/06/07 VMs hold **live trading** — they can't go cold in place. Instead **consolidate onto compute-monster** (see §4), then power the Mac Pro **hardware off for good**.
- Each Mac Pro draws ~**43–50 W idle 24/7** ([Apple](https://support.apple.com/en-us/102839)) ≈ **$63–66/yr each**; three ≈ **~$190/yr**. Beyond power, they're **EOL**: macOS tops out at Monterey (no security updates), and the dual FirePro GPUs are the model's signature failure point at ~13 years old. Retire for reliability/security as much as for power.

## 3. The biggest lever: power-cap the RTX 5090

At KUA rates the RTX 5090 dwarfs every other electric cost. Rated **575 W TGP**, whole-node **up to ~775 W avg / 856 W peak** under load ([TechPowerUp](https://www.techpowerup.com/review/nvidia-geforce-rtx-5090-founders-edition/46.html)).

- **`nvidia-smi -pl <watts>`** caps the board power on Linux (default 575 W; verify min/max with `nvidia-smi -q -d POWER`). For inference/serving (not training), capping to ~**400–450 W** typically costs little throughput while cutting GPU energy ~25–30%.
- Rough math: shaving an average 150 W off a 24/7 node ≈ **~$190/yr** — on par with retiring all three Mac Pros, with zero workload loss.
- **Do this first** — it's a one-line, reversible change with the best $/effort in the whole plan.

**Does capping break jobs? No.** A power limit only throttles GPU clocks (flagged as `SW Power Cap`) to stay in the envelope — jobs **run slower but complete correctly**. It does not kill processes, does not reduce VRAM, and does not cause CUDA/OOM errors. The driver rejects any cap below the card's Min Power Limit (`nvidia-smi -q -d POWER`), so you can't set it dangerously low. The only real risk is **latency**: capping lowers inference throughput / raises latency, which could brush a real-time **trading-inference SLA** — so cap for batch/training freely, but validate latency before capping a live trading path. The setting resets on reboot unless persisted (systemd unit). Sources: [nvidia-smi docs](https://docs.nvidia.com/deploy/nvidia-smi/index.html), [NVML throttle reasons](https://docs.nvidia.com/deploy/nvml-api/group__nvmlClocksThrottleReasons.html).

**Can the DGX Spark be capped the same way? No.** GB10 is an integrated Grace+Blackwell SoC, not a discrete card — `nvidia-smi -pl` is **not supported** (reports N/A, like Jetson/iGPU). Power is bounded by a fixed firmware budget (**140 W SoC inside a 240 W system**), not an operator-tunable limit. The only power lever NVIDIA exposed is the **idle-power firmware update** (ConnectX-7 NIC hot-plug detection → idle ~22–25 W). So for the Spark you can't cap — **you cold it (§1)**, which is the bigger lever anyway. Sources: [NVIDIA DGX Spark power clarification](https://forums.developer.nvidia.com/t/dgx-spark-power-clarification/349668), [release notes](https://docs.nvidia.com/dgx/dgx-spark/release-notes.html).

## Recommended execution order (best $/effort first)

1. **Power-cap the RTX 5090** on daxxon-ai-gpu-01 (`nvidia-smi -pl`, persist via systemd). Biggest lever, reversible, no workload moved. ~$190/yr.
2. **Cold the DGX Spark** (scale `spark-vllm` to zero / relocate → drain → power off → WOL for batch). ~$200–270/yr.
3. **Stand up compute-monster** (5800X + 64 GB + RTX 3060 Ti, §[05](05-memory-sizing-proper-path.md)), migrate worker-04/06/07 workloads, **retire the 3 Mac Pros**. ~$190/yr + EOL risk gone. *Net power note:* this one box (idle ~60–90 W, CPU-load peak ~350–400 W with the 3060 Ti) draws more than any single Mac Pro (~45–50 W idle), but it **replaces all three** while adding a usable GPU — and unlike the Mac Pros it can be **cold-spared via WOL** when idle. If the 3060 Ti isn't doing 24/7 GPU work, cap or idle it; it's a ~200 W part.
4. **Consolidate burst CI** onto a WOL cold-spare node; wake only on demand.

## WOL — how the cold/spin-up tier works

- **Mac Pro 2013:** WOL works from **sleep** (~2.8 W), not full-off; needs "Wake for network access" + wired Ethernet ([Apple](https://www.apple.com/environment/pdf/products/desktops/MacPro_PER_oct2013.pdf)). (Being retired, so mostly moot.)
- **compute-monster (MSI B550-A PRO):** WOL from full **S5** shutdown works on current BIOS — in Click BIOS set **Settings → Advanced → Power Management Setup → ErP Ready = Disabled** and **Settings → Advanced → Wake Up Event Setup → Resume By PCI-E Device = Enabled** ([MSI B550-A PRO support](https://www.msi.com/Motherboard/B550-A-PRO/support)); on Linux arm the NIC with `ethtool -s <if> wol g` and persist via systemd-networkd. Powered-off standby ≈ 1–3 W. Note the onboard NIC is **1 GbE** (RTL8111H), so WOL rides the gigabit link.
- **DGX Spark:** power-cycle/WOL carefully per the CLAUDE.md Spark rules; expect a slow cold start (model reload).
- **Pattern:** keep the always-hot tier sized for steady-state load; WOL-wake a cold node, `kubectl uncordon`, let it absorb the burst, then drain + `kubectl cordon` + power off when the queue drains. Trigger from the CI queue depth (ARC/KEDA) or a manual `wakeonlan <MAC>`.
