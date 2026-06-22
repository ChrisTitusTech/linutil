#!/bin/sh -e

. ../common-script.sh

installFstrim() {
    # fstrim ships with util-linux
    if ! command_exists fstrim; then
        printf "%b\n" "${YELLOW}Installing fstrim (util-linux)...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm util-linux
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add util-linux
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy util-linux
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y util-linux
                ;;
        esac
    else
        printf "%b\n" "${GREEN}fstrim is already installed${RC}"
    fi
}

enableFstrimTimer() {
    if ! systemctl cat fstrim.timer >/dev/null 2>&1; then
        printf "%b\n" "${RED}fstrim.timer is not available on this system; cannot enable periodic TRIM.${RC}"
        exit 1
    fi
    printf "%b\n" "${YELLOW}Enabling weekly fstrim.timer...${RC}"
    "$ESCALATION_TOOL" systemctl enable --now fstrim.timer
}

runInitialTrim() {
    printf "%b\n" "${YELLOW}Running an initial trim on all supported mounted filesystems...${RC}"
    "$ESCALATION_TOOL" fstrim -av || printf "%b\n" "${YELLOW}Some filesystems do not support trim and were skipped.${RC}"
}

checkEnv
checkEscalationTool
installFstrim
enableFstrimTimer
runInitialTrim

if systemctl is-active --quiet fstrim.timer; then
    printf "%b\n" "${GREEN}Periodic SSD TRIM is active (weekly via fstrim.timer).${RC}"
else
    printf "%b\n" "${RED}fstrim.timer could not be activated. Check 'systemctl status fstrim.timer'.${RC}"
fi
