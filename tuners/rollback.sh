sudo systemctl stop obfuscation.service
sudo pkill -f obf- || true
sudo tc qdisc del dev enp1s0 root 2>/dev/null || true
sudo tc qdisc del dev wlp2s0 root 2>/dev/null || true
sudo tc qdisc del dev ifb0 root 2>/dev/null || true
sudo iptables -t mangle -F POSTROUTING || true

