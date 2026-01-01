#!/usr/bin/env bash
# install_obfuscation.sh
# Idempotent installer for the stable, non-morpho obfuscation stack
set -euo pipefail

echo
echo "=== Obfuscation Stack Installer ==="
echo "This script creates scripts, logs, iptables/tc rules and a systemd unit."
echo "Run as a user with sudo privileges."
echo

# -------------------------------------------------------------------------
# 0. Sanity / prerequisites
# -------------------------------------------------------------------------
echo "[+] Ensure apt packages (non-destructive)."
sudo apt update -y >/dev/null 2>&1 || true
# install small utilities we may need (idempotent)
sudo apt install -y iptables iproute2 iputils-ping net-tools tcptraceroute ipset \
    tc jq ncdu htop netcat-openbsd >/dev/null 2>&1 || true

# -------------------------------------------------------------------------
# 1. Create logs (root-owned, secure)
# -------------------------------------------------------------------------
echo "[+] Creating log files (/var/log/obf-*.log)"
sudo touch /var/log/obf-route-rotate.log \
           /var/log/obf-chaff.log \
           /var/log/obf-neural-faux.log \
           /var/log/obf-unified.log \
           /var/log/obf-morpho.log 2>/dev/null || true

sudo chown root:root /var/log/obf-*.log
sudo chmod 644 /var/log/obf-*.log

# -------------------------------------------------------------------------
# 2. Ensure routing table entry 22 obfmark
# -------------------------------------------------------------------------
echo "[+] Ensuring /etc/iproute2/rt_tables contains '22 obfmark'"
if ! grep -qE '^22[[:space:]]+obfmark' /etc/iproute2/rt_tables 2>/dev/null; then
  echo "22 obfmark" | sudo tee -a /etc/iproute2/rt_tables >/dev/null
fi

# -------------------------------------------------------------------------
# 3. Write scripts to /usr/local/bin
# -------------------------------------------------------------------------
BIN=/usr/local/bin
echo "[+] Writing helper scripts to ${BIN}"

# 3.1 route-rotator (single-instance using flock)
sudo tee "${BIN}/obf-route-rotate.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash
# obf-route-rotate.sh - single-instance route rotator (table obfmark)
set -euo pipefail
LOCK="/var/run/obf-route-rotate.lock"
LOG="/var/log/obf-route-rotate.log"
TABLE="obfmark"

exec 9>"$LOCK"
if ! flock -n 9; then
  # another instance is running; exit gracefully
  exit 0
fi

echo "$(date) - route-rotator start pid $$" >> "$LOG"
while true; do
  if (( RANDOM % 2 )); then
    sudo ip route replace default dev enp1s0 table "$TABLE"
    echo "$(date) -> enp1s0" >> "$LOG"
  else
    sudo ip route replace default dev wlp2s0 table "$TABLE" 2>/dev/null && \
      echo "$(date) -> wlp2s0" >> "$LOG"
  fi
  sleep $((4 + RANDOM % 5))
done
EOF

# 3.2 chaff generator (minimal, safe)
sudo tee "${BIN}/obf-chaff.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash
# obf-chaff.sh - UDP chaff generator (local decoy)
set -euo pipefail
LOCK="/var/run/obf-chaff.lock"
LOG="/var/log/obf-chaff.log"

exec 9>"$LOCK"
if ! flock -n 9; then exit 0; fi

while true; do
  # small UDP burst to localhost high ports to create background noise
  dd if=/dev/urandom bs=512 count=1 2>/dev/null | nc -u -w1 127.0.0.1 $((30000 + RANDOM % 20000)) 2>/dev/null || true
  echo "$(date) chaff burst" >> "$LOG"
  sleep 1
done
EOF

# 3.3 neural-faux lightweight generator
sudo tee "${BIN}/obf-neural-faux.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash
# obf-neural-faux.sh - minimal synthetic traffic generator
set -euo pipefail
LOCK="/var/run/obf-neural-faux.lock"
LOG="/var/log/obf-neural-faux.log"

exec 9>"$LOCK"
if ! flock -n 9; then exit 0; fi

while true; do
  SIZE=$((200 + RANDOM % 2000))
  head -c "$SIZE" /dev/urandom | nc -u -w1 127.0.0.1 $((20000 + RANDOM % 20000)) 2>/dev/null || true
  echo "$(date) faux burst $SIZE bytes" >> "$LOG"
  sleep 0.5
done
EOF

# 3.4 unified orchestrator (launches chaff/neural/rotator and ensures qdisc)
sudo tee "${BIN}/obf-unified.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash
# obf-unified.sh - supervisor/orchestrator for the obfuscation stack
set -euo pipefail
LOG="/var/log/obf-unified.log"

# ensure tc + ifb present & basic qdisc
sudo modprobe ifb || true
sudo ip link add ifb0 type ifb 2>/dev/null || true
sudo ip link set ifb0 up 2>/dev/null || true

sudo tc qdisc replace dev enp1s0 root fq_codel || true
sudo tc qdisc replace dev wlp2s0 root fq_codel || true
sudo tc qdisc replace dev ifb0 root netem delay 1ms 1ms || true

# ensure clean single instances
sudo pkill -f /usr/local/bin/obf-route-rotate.sh || true
sudo pkill -f /usr/local/bin/obf-chaff.sh || true
sudo pkill -f /usr/local/bin/obf-neural-faux.sh || true
sleep 0.5

# start components (nohup ensures they keep running)
sudo nohup /usr/local/bin/obf-route-rotate.sh >/dev/null 2>&1 &
sudo nohup /usr/local/bin/obf-chaff.sh >/dev/null 2>&1 &
sudo nohup /usr/local/bin/obf-neural-faux.sh >/dev/null 2>&1 &

echo "$(date) obf-unified started" >> "$LOG"
# keep the orchestrator alive (systemd will supervise this script)
# This process will stay alive; it exits only on system shutdown or failure.
while true; do
  sleep 60
done
EOF

# set ownership + permissions
sudo chown root:root "${BIN}/obf-route-rotate.sh" "${BIN}/obf-chaff.sh" \
                "${BIN}/obf-neural-faux.sh" "${BIN}/obf-unified.sh"

sudo chmod 700 "${BIN}/obf-route-rotate.sh" "${BIN}/obf-chaff.sh" \
                "${BIN}/obf-neural-faux.sh" "${BIN}/obf-unified.sh"

# -------------------------------------------------------------------------
# 4. Apply stable IPTABLES mangle POSTROUTING rules (idempotent-ish)
# -------------------------------------------------------------------------
echo "[+] Applying stable iptables mangle POSTROUTING rules"
# flush only POSTROUTING to avoid interfering with other firewall rules
sudo iptables -t mangle -F POSTROUTING || true

# base mark for policy-based routing
sudo iptables -t mangle -A POSTROUTING -j MARK --set-mark 0x16

# deterministic TTL cycle (every 5 packets)
sudo iptables -t mangle -A POSTROUTING -m statistic --mode nth --every 5 --packet 0 -j TTL --ttl-set 32
sudo iptables -t mangle -A POSTROUTING -m statistic --mode nth --every 5 --packet 1 -j TTL --ttl-set 48
sudo iptables -t mangle -A POSTROUTING -m statistic --mode nth --every 5 --packet 2 -j TTL --ttl-set 64
sudo iptables -t mangle -A POSTROUTING -m statistic --mode nth --every 5 --packet 3 -j TTL --ttl-set 96
sudo iptables -t mangle -A POSTROUTING -m statistic --mode nth --every 5 --packet 4 -j TTL --ttl-set 128

# random TTL noise (30%), and fallback baseline
sudo iptables -t mangle -A POSTROUTING -m statistic --mode random --probability 0.30 -j TTL --ttl-set 128
sudo iptables -t mangle -A POSTROUTING -j TTL --ttl-set 64

# UDP nth marker for special handling
# Note: nft/iptables can be quirky; this works on iptables-nft compatibility layer.
sudo iptables -t mangle -A POSTROUTING -p udp -m statistic --mode nth --every 30 --packet 0 -j MARK --set-mark 0x30 || true

echo "[+] IPTABLES POSTROUTING rules:"
sudo iptables -t mangle -L POSTROUTING -v --line-numbers || true

# -------------------------------------------------------------------------
# 5. Ensure qdiscs + ifb are present (idempotent)
# -------------------------------------------------------------------------
echo "[+] Ensuring fq_codel + ifb0 + netem are present"
sudo tc qdisc replace dev enp1s0 root fq_codel || true
sudo tc qdisc replace dev wlp2s0 root fq_codel || true

sudo modprobe ifb || true
sudo ip link add ifb0 type ifb 2>/dev/null || true
sudo ip link set ifb0 up 2>/dev/null || true
sudo tc qdisc replace dev ifb0 root netem delay 1ms 1ms || true

echo "[+] qdisc:"
sudo tc qdisc show dev enp1s0 || true
sudo tc qdisc show dev wlp2s0 || true
sudo tc qdisc show dev ifb0 || true

# -------------------------------------------------------------------------
# 6. Install systemd unit (single unified service)
# -------------------------------------------------------------------------
SERVICE_PATH=/etc/systemd/system/obfuscation.service
echo "[+] Writing systemd unit to ${SERVICE_PATH}"

sudo tee "${SERVICE_PATH}" >/dev/null <<'EOF'
[Unit]
Description=Unified Obfuscation Stack (route-rotator, chaff, neural-faux)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/obf-unified.sh
Restart=always
RestartSec=5
KillMode=control-group
LimitNOFILE=65536
# Run as root (scripts require root)
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# set permissions for unit file
sudo chmod 644 "${SERVICE_PATH}"

# -------------------------------------------------------------------------
# 7. Enable & start the service
# -------------------------------------------------------------------------
echo "[+] Reloading systemd, enabling and starting obfuscation.service"
sudo systemctl daemon-reload
sudo systemctl enable obfuscation.service
sudo systemctl restart obfuscation.service

# small sleep then status
sleep 1
echo
echo "=== Verification ==="
echo "Processes (obf-):"
pgrep -a -f obf- || true
echo
echo "Systemd status:"
sudo systemctl status obfuscation.service --no-pager || true
echo
echo "IP routing table (obfmark):"
sudo ip rule list || true
sudo ip route show table obfmark || true
echo
echo "IPTABLES POSTROUTING:"
sudo iptables -t mangle -L POSTROUTING -v --line-numbers || true
echo
echo "qdisc summary:"
sudo tc qdisc show dev enp1s0 || true
sudo tc qdisc show dev wlp2s0 || true
sudo tc qdisc show dev ifb0 || true
echo
echo "Logs tail:"
sudo tail -n 6 /var/log/obf-route-rotate.log || true
sudo tail -n 6 /var/log/obf-chaff.log || true
sudo tail -n 6 /var/log/obf-neural-faux.log || true

echo
echo "Install complete. If you want the installer to also remove morpho artifacts, run:"
echo "  sudo pkill -f obf-morpho || true; sudo rm -f /usr/local/bin/obf-morpho* /var/log/obf-morpho.log || true"
echo
echo "To view live logs: sudo journalctl -u obfuscation.service -f"
echo
echo "=== End installer ==="
