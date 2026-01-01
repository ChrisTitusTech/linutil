#!/bin/bash
# unattended-upgrades setup for Ubuntu 24.04 + Mint 22.2 + key repos
# Safe: backups, architecture-aware cleanup, systemd boot config, automated weekly cache cleanup

set -e

# Backup single file with timestamp
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local timestamp
        timestamp=$(date +"%Y%m%d-%H%M%S")
        echo "[*] Backing up $file -> ${file}.bak-$timestamp"
        sudo cp "$file" "${file}.bak-$timestamp"
    fi
}

# Backup directory with timestamp
backup_dir() {
    local dir="$1"
    if [ -d "$dir" ]; then
        local timestamp
        timestamp=$(date +"%Y%m%d-%H%M%S")
        echo "[*] Backing up directory $dir -> ${dir}.bak-$timestamp"
        sudo cp -r "$dir" "${dir}.bak-$timestamp"
    fi
}

echo "[*] Installing prerequisites..."
sudo apt update
sudo apt install -y unattended-upgrades apt-listchanges

# Backup old configs
backup_file /etc/apt/apt.conf.d/50unattended-upgrades
backup_file /etc/apt/apt.conf.d/20auto-upgrades

# Detect system architecture
ARCH=$(dpkg --print-architecture)
echo "[*] Detected system architecture: $ARCH"

# Backup and clean old APT lists
backup_dir /var/lib/apt/lists
echo "[*] Cleaning /var/lib/apt/lists..."
sudo rm -rf /var/lib/apt/lists/*

# Backup and clean old APT archives (keeping only current architecture)
backup_dir /var/cache/apt/archives
echo "[*] Cleaning /var/cache/apt/archives (keeping $ARCH packages)..."
sudo find /var/cache/apt/archives -type f ! -name "*_$ARCH.*" -exec rm -f {} \;

# Configure 50unattended-upgrades
echo "[*] Writing /etc/apt/apt.conf.d/50unattended-upgrades ..."
sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null <<'EOF'
Unattended-Upgrade::Origins-Pattern {
        "origin=Ubuntu,codename=noble";
        "origin=linuxmint,codename=zara";
        "o=microsoft-ubuntu-questing-prod questing,a=questing,n=questing,l=microsoft-ubuntu-questing-prod questing,c=main";
        "o=LP-PPA-danielrichter2007-grub-customizer,a=noble,n=noble,l=Launchpad PPA for Grub Customizer,c=main";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-WithUsers "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";
Unattended-Upgrade::OnlyOnACPower "false";
Unattended-Upgrade::Upgrade-Type "full-upgrade";
EOF

# Configure 20auto-upgrades
echo "[*] Writing /etc/apt/apt.conf.d/20auto-upgrades ..."
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "7";
APT::Periodic::Download-Upgradeable-Packages "7";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "7";
EOF

# Systemd boot config adjustments
SYSTEMD_CONF="/etc/systemd/system.conf"
backup_file "$SYSTEMD_CONF"

# Set a safe default timeout for services if not already set
if ! grep -q "DefaultTimeoutStartSec" "$SYSTEMD_CONF"; then
    echo "DefaultTimeoutStartSec=90s" | sudo tee -a "$SYSTEMD_CONF" > /dev/null
    echo "[*] Added DefaultTimeoutStartSec=90s to $SYSTEMD_CONF"
fi

# Reload systemd and enable unattended-upgrades service
echo "[*] Reloading systemd and enabling unattended-upgrades service..."
sudo systemctl daemon-reexec
sudo systemctl enable --now unattended-upgrades

# Create systemd service & timer for weekly cache cleanup
echo "[*] Creating systemd service and timer for weekly APT cache cleanup..."

SERVICE_FILE="/etc/systemd/system/apt-cache-clean-arch.service"
TIMER_FILE="/etc/systemd/system/apt-cache-clean-arch.timer"

backup_file "$SERVICE_FILE"
backup_file "$TIMER_FILE"

sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Clean APT archives (keep only $ARCH architecture)

[Service]
Type=oneshot
ExecStart=/usr/bin/find /var/cache/apt/archives -type f ! -name "*_$ARCH.*" -exec rm -f {} \;
EOF

sudo tee "$TIMER_FILE" > /dev/null <<EOF
[Unit]
Description=Weekly APT cache cleanup timer

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start timer
sudo systemctl daemon-reload
sudo systemctl enable --now apt-cache-clean-arch.timer

echo "[*] Setup complete."
echo "Dry-run unattended-upgrades test:"
echo "sudo unattended-upgrades -d --dry-run"
echo "Weekly architecture-aware cache cleanup scheduled via systemd timer."
