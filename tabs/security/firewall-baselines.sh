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
    printf "%b\n" "${GREEN}Using Chris Titus Recommended Firewall Rules${RC}"

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
    printf "%b\n" "${GREEN}Enabled Firewall with Baselines!${RC}"
}

revertFirewall() {
    echo "Reverting firewall baselines..."

    $ESCALATION_TOOL ufw disable
    echo "UFW disabled."

    $ESCALATION_TOOL ufw reset
    echo "UFW rules reset to default."

    if command_exists ufw; then
        printf "Do you want to uninstall UFW as well? (y/N): "
        read uninstall_choice
        if [ "$uninstall_choice" = "y" ] || [ "$uninstall_choice" = "Y" ]; then
            case ${PACKAGER} in
                pacman)
                    $ESCALATION_TOOL ${PACKAGER} -Rns --noconfirm ufw
                    ;;
                *)
                    $ESCALATION_TOOL ${PACKAGER} remove -y ufw
                    ;;
            esac
            echo "UFW uninstalled."
        fi
    fi
}

run() {
    checkEnv
    checkEscalationTool
    installPkg
    configureUFW
}

revert() {
    checkEnv
    checkEscalationTool
    revertFirewall
}