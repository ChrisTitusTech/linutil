#!/bin/sh -e

. ../../common-script.sh

setupPaccache() {
    if ! command_exists paccache; then
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm pacman-contrib
    fi

    "$ESCALATION_TOOL" systemctl enable --now paccache.timer 2>/dev/null || true
    printf "%b\n" "${GREEN}paccache.timer enabled (weekly cache cleanup).${RC}"
}

removeOrphans() {
    local orphans
    orphans=$(pacman -Qtdq 2>/dev/null || true)
    if [ -n "$orphans" ]; then
        printf "%b\n" "${YELLOW}Removing orphan packages...${RC}"
        printf "%s\n" "$orphans"
        "$ESCALATION_TOOL" "$PACKAGER" -Rns --noconfirm $orphans 2>/dev/null || true
    else
        printf "%b\n" "${GREEN}No orphan packages found.${RC}"
    fi
}

cleanJournal() {
    "$ESCALATION_TOOL" journalctl --vacuum-time=30d 2>/dev/null || true
    printf "%b\n" "${GREEN}System journal trimmed to 30 days.${RC}"
}

printf "%b\n" "${YELLOW}Arch System Maintenance${RC}"
checkEnv
checkEscalationTool
setupPaccache
removeOrphans
cleanJournal
