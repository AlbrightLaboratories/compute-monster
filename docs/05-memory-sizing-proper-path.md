# 05 — Memory sizing: how much, and why 64 GB is right

This ties the **cluster reality** (what we're retiring) to the **hardware we own** (MSI B550-A PRO + Ryzen 7 5800X + 64 GB DDR4).

## Step 1 — what the new node must absorb

Live cluster snapshot of the three retiring workers:

| Node | CPU cap | RAM cap | Requests (CPU / MEM) | Live use (CPU / MEM) | Pods |
|------|--------:|--------:|---------------------:|---------------------:|-----:|
| kubeadm-worker04 | 4 | 23.5 GiB | 2.97 / 5.8 GiB | 0.78 / 6.0 GiB | 42 |
| kubeadm-worker06 | 4 | 15.6 GiB | 2.85 / 5.6 GiB | 0.35 / 3.8 GiB | 51 |
| kubeadm-worker07 | 3 | 9.7 GiB | 1.36 / 3.0 GiB | 0.68 / 5.5 GiB | 50 |
| **Combined** | **11 vCPU** | **~49 GiB** | **7.2 / 14.3 GiB** | **1.8 / 15.3 GiB** | **143** |

- **CPU:** non-issue. The 5800X presents **16 threads**; combined requests are 7.2 and live use 1.8. Big surplus.
- **Memory:** the only real constraint. You're collapsing **~49 GiB of capacity** onto one box. Live working set ~15 GiB, requests ~14 GiB, but the sum of pod **limits** is ~91 GiB — that burst headroom is today spread across three machines.
- **Pods:** 143 total exceeds the **default kubelet cap of 110**. Plan to raise `--max-pods` (~160) on the new node, or trim/consolidate pods. See [the cluster runbook in the root README](../README.md).

## Step 2 — how much RAM

| Option | Holds working set (~15 GiB)? | Burst headroom | Matches retired capacity (49 GiB)? | Verdict |
|--------|:--:|:--:|:--:|--------|
| 32 GB | yes (~30 GiB usable) | thin — OOM risk under simultaneous burst | no (32 < 49) | Too small |
| **64 GB (installed)** | yes, ~4× headroom | comfortable | **yes, beats it** | ✅ **What we have** |
| 128 GB | yes | large | well beyond | Only if future growth demands it (board max) |

**Answer: 64 GB.** It holds the combined working set with ~4× headroom, beats the 49 GiB being retired, absorbs realistic bursts, and stays well under the CPU/board 128 GB ceiling. **This is already installed and POSTing** — no purchase needed.

## Step 3 — running it well

- Enable **A-XMP** in Click BIOS and target **DDR4-3600 1:1** (FCLK 1800) if the kit supports it; otherwise DDR4-3200 is a solid stable floor. See [03](03-cpu-ryzen-7-5800x.md) / [04](04-memory-ddr4.md).
- If the 64 GB is **4×16** (all four slots), accept a slightly lower top speed — capacity is what matters for this node.
- Run a memory stress pass (MemTest86 / `memtester`) before `kubeadm join`, especially if pushing above the rated XMP speed.

## If you ever need more than 64 GB

Add a **single matched kit** to reach 128 GB — don't pair leftover mismatched sticks. But 64 GB already covers the three-worker consolidation with room to spare, so this is future-only.

## Recommendation

**64 GB is the correct size and it's already in the box.** Enable A-XMP, validate stability, set `--max-pods ~160`, and join the node. Assembly + BIOS steps in [06](06-assembly-and-bios-setup.md).
