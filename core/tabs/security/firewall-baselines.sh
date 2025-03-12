#!/bin/sh -e

. ../common-script.sh

installPkg() {
    if ! command_exists ufw; then
     printf "%b\n" "${YELLOW}Installing UFW...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm ufw
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add ufw
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy ufw
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y ufw
                ;;
        esac
    else
        printf "%b\n" "${GREEN}UFW is already installed${RC}"
    fi
}

configureUFW() {
    printf "%b\n" "${YELLOW}Using Chris Titus Recommended Firewall Rules${RC}"

    printf "%b\n" "${YELLOW}Disabling UFW${RC}"
    "$ESCALATION_TOOL" ufw disable

    printf "%b\n" "${YELLOW}Limiting port 22/tcp (UFW)${RC}"
    "$ESCALATION_TOOL" ufw limit 22/tcp

    printf "%b\n" "${YELLOW}Allowing port 80/tcp (UFW)${RC}"
    "$ESCALATION_TOOL" ufw allow 80/tcp

    printf "%b\n" "${YELLOW}Allowing port 443/tcp (UFW)${RC}"
    "$ESCALATION_TOOL" ufw allow 443/tcp

    printf "%b\n" "${YELLOW}Denying Incoming Packets by Default(UFW)${RC}"
    "$ESCALATION_TOOL" ufw default deny incoming

    printf "%b\n" "${YELLOW}Allowing Outcoming Packets by Default(UFW)${RC}"
    "$ESCALATION_TOOL" ufw default allow outgoing

    "$ESCALATION_TOOL" ufw enable
    printf "%b\n" "${GREEN}Enabled Firewall with Baselines!${RC}"
}

checkEnv
checkEscalationTool
installPkg
configureUFW
