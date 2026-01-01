#!/usr/bin/env bash
#
# advanced_network_tests.sh
# Runs TCP traceroutes and MTU discovery tests for multiple targets
#

# === CONFIGURATION ===
TARGETS=("8.8.8.8" "1.1.1.1" "74.125.138.139")
PORTS=(80 443)      # common TCP ports to test with TCP traceroute
MTU_MAX=1500        # base MTU to probe downward
LOGDIR="advanced_network_tests_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOGDIR"

echo "Advanced network test started at $(date)" | tee "$LOGDIR/summary.txt"

# --- TCP TRACEROUTE ---
echo "=== TCP TRACEROUTE ===" | tee -a "$LOGDIR/summary.txt"
for host in "${TARGETS[@]}"; do
  for port in "${PORTS[@]}"; do
    echo "TCP traceroute -> $host port $port" | tee -a "$LOGDIR/summary.txt"
    sudo traceroute -T -p "$port" -n "$host" | tee "$LOGDIR/tcp_traceroute_${host}_${port}.log"
    echo "" >> "$LOGDIR/summary.txt"
  done
done

# --- PATH MTU DISCOVERY (ICMP DF tests) ---
echo "=== PATH MTU DISCOVERY (ICMP DF) ===" | tee -a "$LOGDIR/summary.txt"
for host in "${TARGETS[@]}"; do
  echo "MTU probing -> $host" | tee -a "$LOGDIR/summary.txt"
  mtu_size=$MTU_MAX
  while [ "$mtu_size" -ge 500 ]; do
    echo "Testing MTU ~$mtu_size" | tee -a "$LOGDIR/summary.txt"
    ping -M do -s "$((mtu_size-28))" -c 1 "$host" &> "$LOGDIR/mtu_${host}_${mtu_size}.log"
    if grep -q "Frag needed" "$LOGDIR/mtu_${host}_${mtu_size}.log"; then
      # MTU too large, try smaller
      mtu_size=$((mtu_size-20))
    else
      echo "Possible passing MTU: $mtu_size" | tee -a "$LOGDIR/summary.txt"
      break
    fi
  done
  echo "" >> "$LOGDIR/summary.txt"
done

echo "Tests completed at $(date)" | tee -a "$LOGDIR/summary.txt"
echo "Logs stored in: $LOGDIR"

