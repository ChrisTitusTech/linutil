#!/usr/bin/env bash
set -e

# Apply VM tuning
echo 5 > /proc/sys/vm/swappiness
echo 50 > /proc/sys/vm/vfs_cache_pressure
echo 10 > /proc/sys/vm/dirty_ratio
echo 5 > /proc/sys/vm/dirty_background_ratio

# Verification
for param in swappiness vfs_cache_pressure dirty_ratio dirty_background_ratio; do
  val=$(sysctl -n vm.$param)
  echo "vm.$param = $val"
done

