#!/bin/sh -e

. ../../common-script.sh

setupZram() {
    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm zram-generator

    local conf="/etc/systemd/zram-generator.conf"
    "$ESCALATION_TOOL" tee "$conf" > /dev/null << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF

    "$ESCALATION_TOOL" systemctl daemon-reexec
    "$ESCALATION_TOOL" systemctl start systemd-zram-setup@zram0 2>/dev/null || true

    local sysctl_conf="/etc/sysctl.d/99-vm-zram-parameters.conf"
    "$ESCALATION_TOOL" tee "$sysctl_conf" > /dev/null << 'EOF'
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF

    printf "%b\n" "${GREEN}zram configured: zstd compression, swappiness=10.${RC}"
    printf "%b\n" "${YELLOW}Reboot or run: sudo systemctl start systemd-zram-setup@zram0${RC}"
}

checkEnv
checkEscalationTool
setupZram
