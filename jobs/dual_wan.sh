#!/bin/bash
# dual_wan.sh - Linux: Ethernet downloads, Wi-Fi uploads
# Detect interfaces automatically or fallback to manual values

# --- CONFIG ---
ETH_IF=enx00e04c680c28  # Ethernet
WIFI_IF=wlp2s0           # Wi-Fi

# Get current IPs
ETH_IP=$(ip -4 addr show dev $ETH_IF | awk '/inet /{print $2}' | cut -d/ -f1)
WIFI_IP=$(ip -4 addr show dev $WIFI_IF | awk '/inet /{print $2}' | cut -d/ -f1)

# --- CREATE TABLES ---
grep -q "200 eth" /etc/iproute2/rt_tables || echo "200 eth" | sudo tee -a /etc/iproute2/rt_tables
grep -q "201 wifi" /etc/iproute2/rt_tables || echo "201 wifi" | sudo tee -a /etc/iproute2/rt_tables

# --- FLUSH PREVIOUS ENTRIES ---
sudo ip route flush table eth 2>/dev/null
sudo ip route flush table wifi 2>/dev/null
sudo ip rule del from $ETH_IP table eth 2>/dev/null
sudo ip rule del from $WIFI_IP table wifi 2>/dev/null

# --- ADD DEVICE-ONLY DEFAULT ROUTES ---
sudo ip route add default dev $ETH_IF table eth
sudo ip route add default dev $WIFI_IF table wifi

# --- ADD SOURCE-BASED RULES ---
sudo ip rule add from $ETH_IP table eth
sudo ip rule add from $WIFI_IP table wifi

# --- FLUSH CACHE ---
sudo ip route flush cache

# --- SUMMARY ---
echo "ETH_IP=$ETH_IP via $ETH_IF (downloads)"
echo "WIFI_IP=$WIFI_IP via $WIFI_IF (uploads)"
echo
echo "Routing tables:"
ip route show table eth
ip route show table wifi
echo
echo "IP rules:"
ip rule show

