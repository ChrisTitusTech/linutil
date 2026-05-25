#!/bin/sh -e

. ../common-script.sh

installZramPkg() {
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm zram-generator
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y systemd-zram-generator
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y zram-generator
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install zram-generator
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add zram-generator
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy zram-generator
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y zram-generator
            ;;
        *)
            "$ESCALATION_TOOL" "$PACKAGER" install -y zram-generator
            ;;
    esac
}

setupZram() {
    installZramPkg

    conf="/etc/systemd/zram-generator.conf"
    "$ESCALATION_TOOL" tee "$conf" > /dev/null << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF

    "$ESCALATION_TOOL" systemctl daemon-reexec
    "$ESCALATION_TOOL" systemctl start systemd-zram-setup@zram0 2>/dev/null || true

    sysctl_conf="/etc/sysctl.d/99-vm-zram-parameters.conf"
    "$ESCALATION_TOOL" tee "$sysctl_conf" > /dev/null << 'EOF'
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF

    printf "%b\n" "${GREEN}zram configured: zstd compression, swappiness=10.${RC}"
    printf "%b\n" "${YELLOW}Reboot or run: sudo systemctl start systemd-zram-setup@zram0${RC}"
}

checkEnv
setupZram
