#!/bin/sh -e

. ../common-script.sh

cleanup_system() {
    printf "%b\n" "${YELLOW}Performing system cleanup...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            elevated_execution "$PACKAGER" clean
            elevated_execution "$PACKAGER" autoremove -y
            elevated_execution "$PACKAGER" autoclean
            elevated_execution du -h /var/cache/apt
            elevated_execution "$PACKAGER" clean
            ;;
        zypper)
            elevated_execution "$PACKAGER" clean -a
            elevated_execution "$PACKAGER" tidy
            elevated_execution "$PACKAGER" cc -a
            ;;
        dnf)
            elevated_execution "$PACKAGER" clean all
            elevated_execution "$PACKAGER" autoremove -y
            ;;
        pacman)
            elevated_execution "$PACKAGER" -Sc --noconfirm
            elevated_execution "$PACKAGER" -Rns $(pacman -Qtdq) --noconfirm > /dev/null 2>&1
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            return 1
            ;;
    esac
}

common_cleanup() {
    elevated_execution find /var/tmp -type f -atime +5 -delete
    elevated_execution find /tmp -type f -atime +5 -delete
    elevated_execution find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
    elevated_execution journalctl --vacuum-time=3d
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
