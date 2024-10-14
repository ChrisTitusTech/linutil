#!/bin/sh -e

. ../common-script.sh

installPkg() {
    if ! command_exists ufw; then
     printf "%b\n" "${YELLOW}Installing UFW...${RC}"
        case "$PACKAGER" in
            pacman)
                elevated_execution "$PACKAGER" -S --needed --noconfirm ufw
                ;;
            *)
                elevated_execution "$PACKAGER" install -y ufw
                ;;
        esac
    else
        printf "%b\n" "${GREEN}UFW is already installed${RC}"
    fi
}

configureUFW() {
    printf "%b\n" "${YELLOW}Using Chris Titus Recommended Firewall Rules${RC}"

    printf "%b\n" "${YELLOW}Disabling UFW${RC}"
    elevated_execution ufw disable

    printf "%b\n" "${YELLOW}Limiting port 22/tcp (UFW)${RC}"
    elevated_execution ufw limit 22/tcp

    printf "%b\n" "${YELLOW}Allowing port 80/tcp (UFW)${RC}"
    elevated_execution ufw allow 80/tcp

    printf "%b\n" "${YELLOW}Allowing port 443/tcp (UFW)${RC}"
    elevated_execution ufw allow 443/tcp

    printf "%b\n" "${YELLOW}Denying Incoming Packets by Default(UFW)${RC}"
    elevated_execution ufw default deny incoming

    printf "%b\n" "${YELLOW}Allowing Outcoming Packets by Default(UFW)${RC}"
    elevated_execution ufw default allow outgoing

    elevated_execution ufw enable
    printf "%b\n" "${GREEN}Enabled Firewall with Baselines!${RC}"
}

checkEnv
checkEscalationTool
installPkg
configureUFW
