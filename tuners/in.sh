#!/usr/bin/env bash
set -euo pipefail

### ========= CONFIG (minimal + safe defaults) =========
CLOUDFLARED_BIN="/usr/local/bin/cloudflared"
CLOUDFLARED_USER="cloudflared"
CLOUDFLARED_GROUP="cloudflared"
CLOUDFLARED_PORT="5053"   # avoids 53 / avahi conflicts
DOH_ENDPOINT="https://cloudflare-dns.com/dns-query"
TMP_BIN="/tmp/cloudflared.bin"

### ========= UTILS =========
log() { echo -e "\n==> $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Must be run as root"

### ========= ARCH DETECTION =========
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  CF_ARCH="amd64" ;;
  aarch64) CF_ARCH="arm64" ;;
  armv7l)  CF_ARCH="arm" ;;
  *) die "Unsupported architecture: $ARCH" ;;
esac

CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}"

### ========= DEPENDENCIES =========
log "Ensuring base dependencies"
apt update -y
apt install -y ca-certificates curl

### ========= USER / GROUP =========
log "Ensuring cloudflared system user"
getent group "$CLOUDFLARED_GROUP" >/dev/null || groupadd --system "$CLOUDFLARED_GROUP"
id "$CLOUDFLARED_USER" >/dev/null 2>&1 || \
  useradd --system --no-create-home --gid "$CLOUDFLARED_GROUP" \
          --shell /usr/sbin/nologin "$CLOUDFLARED_USER"

### ========= DOWNLOAD =========
log "Downloading cloudflared (${CF_ARCH})"
curl -fL --retry 3 --connect-timeout 10 \
     -o "$TMP_BIN" "$CLOUDFLARED_URL"

[[ -s "$TMP_BIN" ]] || die "Downloaded file is empty"

file "$TMP_BIN" | grep -q ELF || die "Downloaded file is not executable"

install -m 0755 "$TMP_BIN" "$CLOUDFLARED_BIN"
rm -f "$TMP_BIN"

log "Installed: $CLOUDFLARED_BIN"
"$CLOUDFLARED_BIN" --version

### ========= SYSTEMD SERVICE =========
log "Installing systemd service"

cat >/etc/systemd/system/cloudflared-dns.service <<EOF
[Unit]
Description=Cloudflared DNS over HTTPS proxy
After=network-online.target
Wants=network-online.target

[Service]
User=${CLOUDFLARED_USER}
Group=${CLOUDFLARED_GROUP}
ExecStart=${CLOUDFLARED_BIN} proxy-dns \
  --port ${CLOUDFLARED_PORT} \
  --address 127.0.0.1 \
  --upstream ${DOH_ENDPOINT}
Restart=on-failure
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now cloudflared-dns.service

### ========= SYSTEMD-RESOLVED =========
log "Configuring systemd-resolved"

RESOLVED_CONF="/etc/systemd/resolved.conf"

sed -i 's/^#\?DNS=.*/DNS=127.0.0.1/' "$RESOLVED_CONF"
sed -i 's/^#\?DNSStubListener=.*/DNSStubListener=yes/' "$RESOLVED_CONF"

systemctl restart systemd-resolved

### ========= VALIDATION =========
log "Validation"

ss -ltnup | grep ":${CLOUDFLARED_PORT}" || die "cloudflared not listening"

resolvectl query example.com >/dev/null || die "DNS resolution failed"

log "SUCCESS"
echo "cloudflared DNS running on 127.0.0.1:${CLOUDFLARED_PORT}"
echo "systemd-resolved forwarding enabled"
