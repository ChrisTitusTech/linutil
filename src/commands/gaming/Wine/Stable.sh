#!/bin/sh -e

. ../../common-script.sh

installDependencies() {

    echo -e "${YELLOW}Installing dependencies...${RC}"
    case $PACKAGER in
        pacman)
            if ! grep -q "^\s*\[multilib\]" /etc/pacman.conf; then
                echo "[multilib]" | $ESCALATION_TOOL tee -a /etc/pacman.conf
                echo "Include = /etc/pacman.d/mirrorlist" | $ESCALATION_TOOL tee -a /etc/pacman.conf
                $ESCALATION_TOOL "$PACKAGER" -Syu
            else
                echo "Multilib is already enabled."
            fi
        ;;
        apt-get|nala)
        ;;
        dnf)
        ;;
        zypper)
        ;;
    esac
}

installWine() {
    echo "Install Wine Stable Branch if not already installed..."
    if ! command_exists wine; then
        echo -e "${YELLOW}Installing Wine...${RC}"
        case $PACKAGER in
        pacman)
            $ESCALATION_TOOL "${PACKAGER}" -S wine wine-mono wine-gecko
            ;;
        apt-get|nala)
            $ESCALATION_TOOL "${PACKAGER}" install wine64
            ;;
        dnf)
            $ESCALATION_TOOL "${PACKAGER}" install wine
            ;;
        zypper)

        esac

    else
        echo "Wine is already installed."
    fi


}



checkEnv
checkEscalationTool
installDependencies
installWine