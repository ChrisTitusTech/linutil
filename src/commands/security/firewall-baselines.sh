#!/bin/sh -e

. ../common-script.sh

installPkg() {
    echo "Install UFW if not already installed..."
    if ! command_exists ufw; then
        case ${PACKAGER} in
            pacman)
                sudo "${PACKAGER}" -S --needed --noconfirm ufw
                ;;
            *)
                sudo "${PACKAGER}" install -y ufw
                ;;
        esac
    else
        echo "UFW is already installed."
    fi
}

configureUFW() {
    echo -e "${GREEN}Using Chris Titus Recommended Firewall Rules${RC}"

    echo "Disabling UFW"
    sudo ufw disable

    echo "Limiting port 22/tcp (UFW)"
    sudo ufw limit 22/tcp

    echo "Allowing port 80/tcp (UFW)"
    sudo ufw allow 80/tcp

    echo "Allowing port 443/tcp (UFW)"
    sudo ufw allow 443/tcp

    echo "Denying Incoming Packets by Default(UFW)"
    sudo ufw default deny incoming

    echo "Allowing Outcoming Packets by Default(UFW)"
    sudo ufw default allow outgoing

    sudo ufw enable
    echo -e "${GREEN}Enabled Firewall with Baselines!${RC}"
}

checkEnv
installPkg
configureUFW
