# Configure Wi-Fi Regulatory Domain
# The wireless-regdb package includes a database of wireless rules (allowed frequencies, channels, power limits) for various countries. Setting the right region for your location can unlock specific Wi-Fi channels (such as channels 12/13 or 5GHz/6GHz bands) that may be limited by default, helping to improve your Wi-Fi performance and connection quality.

sudo micro /etc/conf.d/wireless-regdom >> /dev/null 2>&1 <<EOF
REGDOM="DE"
EOF
iw reg get