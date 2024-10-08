#!/bin/sh -e

. ../common-script.sh

cleanup_system() {
    printf "%b\n" "${YELLOW}Performing system cleanup...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" clean
            "$ESCALATION_TOOL" "$PACKAGER" autoremove -y
            "$ESCALATION_TOOL" "$PACKAGER" autoclean
            "$ESCALATION_TOOL" du -h /var/cache/apt
            "$ESCALATION_TOOL" "$PACKAGER" clean
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" clean -a
            "$ESCALATION_TOOL" "$PACKAGER" tidy
            "$ESCALATION_TOOL" "$PACKAGER" cc -a
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" clean all
            "$ESCALATION_TOOL" "$PACKAGER" autoremove -y
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Sc --noconfirm
            "$ESCALATION_TOOL" "$PACKAGER" -Rns $(pacman -Qtdq) --noconfirm > /dev/null 2>&1
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            return 1
            ;;
    esac
}

common_cleanup() {
    "$ESCALATION_TOOL" find /var/tmp -type f -atime +5 -delete
    "$ESCALATION_TOOL" find /tmp -type f -atime +5 -delete
    "$ESCALATION_TOOL" find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
    "$ESCALATION_TOOL" journalctl --vacuum-time=3d
}

clean_data() {
    printf "%b" "${YELLOW}Clean up old cache files and empty the trash? (y/N): ${RC}"
    read -r clean_response
    case $clean_response in
        y|Y)
            printf "%b\n" "${YELLOW}Cleaning up old cache files and emptying trash...${RC}"
            find "$HOME/.cache/" -type f -atime +5 -delete
            find "$HOME/.local/share/Trash" -mindepth 1 -delete
            printf "%b\n" "${GREEN}Cache and trash cleanup completed.${RC}"
            ;;
        *)
            printf "%b\n" "${YELLOW}Skipping cache and trash cleanup.${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
cleanup_system
common_cleanup
clean_data
