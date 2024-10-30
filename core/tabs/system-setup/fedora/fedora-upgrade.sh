#!/bin/sh -e

. ../../common-script.sh

current_version=$(rpm -E '%{fedora}')
next_version=$((current_version + 1))

update() {
    printf "%b\n" "${YELLOW}Make sure your system is fully updated; if not, update it first and reboot once.${RC}"
    printf "%b\n" "${CYAN}Your current Fedora version is $current_version.${RC}"
    printf "%b\n" "${CYAN}The next available version is $next_version.${RC}"
    
    printf "%b\n" "${YELLOW}Do you want to update to $next_version? (y/n): ${RC}"  
    read -r response
    
    case "$response" in
        y|Y)
            printf "%b\n" "${CYAN}Preparing to update to $next_version...${RC}"
        
            if ! "$ESCALATION_TOOL" "$PACKAGER" install dnf-plugin-system-upgrade -y; then
                printf "%b\n" "${RED}Failed to install dnf-plugin-system-upgrade.${RC}"
                exit 1
            fi
        
            if ! "$ESCALATION_TOOL" "$PACKAGER" system-upgrade download --releasever="$next_version" -y ; then
                printf "%b\n" "${RED}Failed to download the upgrade packages.${RC}"
                exit 1
            fi

            printf "%b\n" "${YELLOW}Do you want to reboot now to apply the upgrade? (y/n): ${RC}"
            read -r reboot_response

            case "$reboot_response" in
                y|Y)
                    printf "%b\n" "${YELLOW}Rebooting to apply the upgrade...${RC}"
                    "$ESCALATION_TOOL" "$PACKAGER" system-upgrade reboot
                    ;;
                *)
                    printf "%b\n" "${YELLOW}You can reboot later to apply the upgrade.${RC}"
                    ;;
            esac
            ;;
        *)
            printf "%b\n" "${RED}No upgrade performed.${RC}"
            ;;
    esac
}

post_upgrade() {
    printf "%b\n" "${YELLOW}Running post-upgrade tasks...${RC}"
    
    case "$PACKAGER" in
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" autoremove  
            "$ESCALATION_TOOL" "$PACKAGER" distro-sync -y
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER.${RC}"
            exit 1
            ;;
    esac
}

checkEnv
checkEscalationTool

printf "%b\n" "${YELLOW}Select an option:${RC}"
printf "%b\n" "${GREEN}1. Upgrade to the next Fedora version${RC}"
printf "%b\n" "${GREEN}2. Run post-upgrade tasks${RC}"
read -r choice

case "$choice" in
    1)
        update
        ;;
    2)
        post_upgrade
        ;;
    *)
        printf "%b\n" "${RED}Invalid option. Please select 1 or 2.${RC}"
        exit 1
        ;;
esac
