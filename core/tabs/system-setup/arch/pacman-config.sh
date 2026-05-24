#!/bin/sh -e

. ../../common-script.sh

configurePacman() {
    conf="/etc/pacman.conf"

    if [ ! -f "$conf" ]; then
        printf "%b\n" "${RED}${conf} not found.${RC}"
        exit 1
    fi

    "$ESCALATION_TOOL" sed -i 's/^#Color/Color/' "$conf"
    "$ESCALATION_TOOL" sed -i '/^Color/a ILoveCandy' "$conf"
    "$ESCALATION_TOOL" sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' "$conf"
    "$ESCALATION_TOOL" sed -i 's/^#ParallelDownloads/ParallelDownloads/' "$conf"
    if ! grep -q "^ParallelDownloads" "$conf"; then
        printf "%b\n" "${YELLOW}Adding ParallelDownloads...${RC}"
        "$ESCALATION_TOOL" sed -i '/^#ParallelDownloads/a ParallelDownloads = 5' "$conf"
    fi
    "$ESCALATION_TOOL" sed -i "/\[multilib\]/,/Include/"'s/^#//' "$conf"

    printf "%b\n" "${GREEN}pacman.conf configured: Color, ILoveCandy, VerbosePkgLists, ParallelDownloads=5, multilib enabled.${RC}"
}

configureMakepkg() {
    conf="/etc/makepkg.conf"

    cores=$(nproc)
    "$ESCALATION_TOOL" sed -i "s/^#MAKEFLAGS=\"-j[0-9]*\"/MAKEFLAGS=\"-j${cores}\"/" "$conf"
    "$ESCALATION_TOOL" sed -i "s/^MAKEFLAGS=\"-j[0-9]*\"/MAKEFLAGS=\"-j${cores}\"/" "$conf"
    if ! grep -q "^MAKEFLAGS" "$conf"; then
        printf "%b\n" "${YELLOW}Adding MAKEFLAGS...${RC}"
        printf "MAKEFLAGS=\"-j%s\"\n" "$cores" | "$ESCALATION_TOOL" tee -a "$conf" > /dev/null
    fi
    printf "%b\n" "${GREEN}MAKEFLAGS set to -j${cores} in makepkg.conf${RC}"
}

checkEnv
configurePacman
configureMakepkg
