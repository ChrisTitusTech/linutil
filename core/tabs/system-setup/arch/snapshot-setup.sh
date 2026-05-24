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

    if [ -f "/etc/snapper/configs/root" ]; then
        printf "%s\n" "${RED}Error: Existing Snapper 'root' configuration detected. Aborting.${RC}" >&2
        exit 1
    fi

    if mountpoint -q "/.snapshots"; then
        printf "%s\n" "${RED}Error: /.snapshots is actively mounted. Aborting.${RC}" >&2
        exit 1
    fi

    if [ -d "/.snapshots" ]; then
        if "$ESCALATION_TOOL" rmdir "/.snapshots" 2>/dev/null; then
            printf "%s\n" "${GREEN}Removed empty /.snapshots directory.${RC}"
        else
            printf "%s\n" "${RED}Error: /.snapshots exists and is not empty or could not be removed. Aborting to avoid data loss.${RC}" >&2
            exit 1
        fi
    fi

    "$ESCALATION_TOOL" snapper -c root create-config /

    "$ESCALATION_TOOL" systemctl enable --now snapper-timeline.timer snapper-cleanup.timer 2>/dev/null || true
    "$ESCALATION_TOOL" systemctl enable --now grub-btrfsd 2>/dev/null || true

    printf "%b\n" "${GREEN}Snapper configured with hourly snapshots.${RC}"
    printf "%b\n" "${GREEN}snap-pac installed (auto snapshots on pacman operations).${RC}"
    printf "%b\n" "${GREEN}grub-btrfs installed (boot into snapshots from GRUB menu).${RC}"
}

checkEnv
checkBtrfs
setupSnapper
