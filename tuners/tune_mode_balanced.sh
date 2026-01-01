#!/usr/bin/env bash
# Run as root
set -e

LOG_DIR="/var/log/perf_tune"
mkdir -p "$LOG_DIR"
echo "[`date`] → Applying balanced profile" >> "$LOG_DIR/profile.log"

for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  if [ -w "$cpu" ]; then
    echo ondemand > "$cpu"
    echo "Set $cpu → ondemand" >> "$LOG_DIR/profile.log"
  fi
done

echo "vm.swappiness=30" | tee /etc/sysctl.d/99-swappiness.conf
echo "vm.vfs_cache_pressure=100" | tee /etc/sysctl.d/99-vfs_cache_pressure.conf
sysctl -p
echo "Applied vm.swappiness=30 and vm.vfs_cache_pressure=100" >> "$LOG_DIR/profile.log"

MAIN_DEV=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print $1; exit}')
if [ -n "$MAIN_DEV" ]; then
  SCHED_PATH="/sys/block/${MAIN_DEV}/queue/scheduler"
  if [ -w "$SCHED_PATH" ]; then
    echo mq-deadline > "$SCHED_PATH"
    echo "Set scheduler of /sys/block/${MAIN_DEV} → mq-deadline" >> "$LOG_DIR/profile.log"
  else
    echo "WARNING: could not write scheduler path $SCHED_PATH" >> "$LOG_DIR/profile.log"
  fi
else
  echo "WARNING: main disk device not detected" >> "$LOG_DIR/profile.log"
fi

echo "[`date`] → Balanced profile applied" >> "$LOG_DIR/profile.log"

