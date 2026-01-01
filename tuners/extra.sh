#!/usr/bin/env bash
set -e

# Enable kernel logging rate limit (prevent syslog spam)
sudo sysctl -w net.core.message_cost=50 >/dev/null
sudo sysctl -w net.core.message_burst=10 >/dev/null

# Create chain cleanly
sudo iptables -N PORTSCAN 2>/dev/null || true
sudo iptables -F PORTSCAN

# 1. Allow reasonable bursts (reduce false positives)
sudo iptables -A PORTSCAN -p tcp --tcp-flags SYN,ACK,FIN,RST ALL \
    -m limit --limit 1/second --limit-burst 4 \
    -j RETURN

# 2. Log only when rate limit exceeded
sudo iptables -A PORTSCAN \
    -j LOG --log-prefix "PORTSCAN DETECTED: " --log-level 4

# 3. Drop the suspicious packets
sudo iptables -A PORTSCAN -j DROP

# 4. Apply to inbound packets only
sudo iptables -A INPUT -p tcp -j PORTSCAN

echo "Port scan protection enabled."

