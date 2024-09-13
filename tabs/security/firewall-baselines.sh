#!/bin/sh -e

. ../common-script.sh

installPkg() {
    echo "Install UFW if not already installed..."
    if ! command_exists ufw; then
        case ${PACKAGER} in
            pacman)
                $ESCALATION_TOOL "${PACKAGER}" -S --needed --noconfirm ufw
                ;;
            *)
                $ESCALATION_TOOL "${PACKAGER}" install -y ufw
                ;;
        esac
    else
        echo "UFW is already installed."
    fi
}

configureUFW() {
    echo -e "${GREEN}Using Chris Titus Recommended Firewall Rules${RC}"

    echo "Disabling UFW"
    $ESCALATION_TOOL ufw disable

    echo "Limiting port 22/tcp (UFW)"
    $ESCALATION_TOOL ufw limit 22/tcp

    echo "Allowing port 80/tcp (UFW)"
    $ESCALATION_TOOL ufw allow 80/tcp

    echo "Allowing port 443/tcp (UFW)"
    $ESCALATION_TOOL ufw allow 443/tcp

    echo "Denying Incoming Packets by Default(UFW)"
    $ESCALATION_TOOL ufw default deny incoming

    echo "Allowing Outcoming Packets by Default(UFW)"
    $ESCALATION_TOOL ufw default allow outgoing

    $ESCALATION_TOOL ufw enable
    echo -e "${GREEN}Enabled Firewall with Baselines!${RC}"
}

checkEnv
checkEscalationTool
installPkg
configureUFW
