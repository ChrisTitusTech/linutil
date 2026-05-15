#!/bin/sh -e

. ../../common-script.sh

checkBtrfs() {
    if ! command_exists btrfs; then
        printf "%b\n" "${RED}btrfs-progs not installed. Install it first.${RC}"
        exit 1
    fi

    if ! mount | grep -q "btrfs"; then
        printf "%b\n" "${RED}No Btrfs filesystem detected. Snapshots require Btrfs.${RC}"
        exit 1
    fi
}

setupSnapper() {
    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm snapper snap-pac grub-btrfs

    if [ -d "/.snapshots" ] && mountpoint -q "/.snapshots"; then
        "$ESCALATION_TOOL" umount /.snapshots 2>/dev/null || true
    fi
    "$ESCALATION_TOOL" rm -rf /.snapshots 2>/dev/null || true

    "$ESCALATION_TOOL" snapper -c root create-config /

    "$ESCALATION_TOOL" systemctl enable --now snapper-timeline.timer snapper-cleanup.timer 2>/dev/null || true
    "$ESCALATION_TOOL" systemctl enable --now grub-btrfsd 2>/dev/null || true

    printf "%b\n" "${GREEN}Snapper configured with hourly snapshots.${RC}"
    printf "%b\n" "${GREEN}snap-pac installed (auto snapshots on pacman operations).${RC}"
    printf "%b\n" "${GREEN}grub-btrfs installed (boot into snapshots from GRUB menu).${RC}"
}

checkEnv
checkEscalationTool
checkBtrfs
setupSnapper
