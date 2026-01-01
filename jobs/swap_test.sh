#!/usr/bin/env bash
# swap_test_fixed.sh - gradual, safe swap/Zswap stress tester using /proc/meminfo (robust).

SWAP_THRESHOLD_MB=500   # When swap used (MB) >= this, stop allocating and observe
ALLOC_STEP_MB=512       # MB to allocate per step
MAX_ALLOC_MB=15000      # Safety ceiling, do not exceed (MB)
HOLD_SECONDS=5          # Seconds to hold after threshold hit

echo "Starting swap/Zswap stress test"
echo "Current swap:"
swapon --show
echo -n "Zswap enabled? "; cat /sys/module/zswap/parameters/enabled 2>/dev/null || echo "N/A"
echo

python3 - "$ALLOC_STEP_MB" "$MAX_ALLOC_MB" "$SWAP_THRESHOLD_MB" "$HOLD_SECONDS" <<'PYCODE'
import sys, time

# params passed as shell args (safe)
alloc_step_mb = int(sys.argv[1])
max_alloc_mb   = int(sys.argv[2])
swap_threshold_mb = int(sys.argv[3])
hold_seconds = int(sys.argv[4])

ALLOC_STEP = alloc_step_mb * 1024 * 1024
MAX_ALLOC = max_alloc_mb * 1024 * 1024
SWAP_THRESHOLD = swap_threshold_mb * 1024 * 1024

def swap_used_bytes():
    with open('/proc/meminfo','r') as f:
        lines = f.read().splitlines()
    info = {}
    for line in lines:
        parts = line.split()
        if len(parts) >= 2:
            key = parts[0].rstrip(':')
            try:
                info[key] = int(parts[1])  # kB
            except ValueError:
                pass
    total_kb = info.get('SwapTotal', 0)
    free_kb  = info.get('SwapFree', 0)
    used_bytes = (total_kb - free_kb) * 1024
    return used_bytes

allocs = []
allocated = 0

print(f"Alloc step: {alloc_step_mb} MB, max: {max_alloc_mb} MB, threshold: {swap_threshold_mb} MB")

try:
    while allocated < MAX_ALLOC:
        try:
            allocs.append(bytearray(ALLOC_STEP))
            allocated += ALLOC_STEP
        except MemoryError:
            print("MemoryError: cannot allocate more, stopping allocation.")
            break

        used = swap_used_bytes()
        print(f"Allocated {allocated//(1024*1024)} MB — Swap used {used//(1024*1024)} MB")
        sys.stdout.flush()

        if used >= SWAP_THRESHOLD:
            print("Swap threshold reached. Holding allocation for observation.")
            time.sleep(hold_seconds)
            break
        time.sleep(0.5)

finally:
    allocs.clear()
    print("Memory released. Exiting.")
PYCODE

echo
echo "Post-test swap state:"
swapon --show
echo -n "Zswap enabled? "; cat /sys/module/zswap/parameters/enabled 2>/dev/null || echo "N/A"
echo "Done."

