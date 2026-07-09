#!/bin/sh -e

. ../../common-script.sh

installHeliumBrowser() {
    if ! command_exists Helium && ! command_exists helium; then
        printf "%b\n" "${YELLOW}Installing Helium Browser...${RC}"
        case "$PACKAGER" in
        pacman)
            "$AUR_HELPER" -S --needed --noconfirm helium-browser-bin
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" copr enable imput/helium
            "$ESCALATION_TOOL" "$PACKAGER" install -y helium-bin
            ;;
        nala|apt-get)
            "$ESCALATION_TOOL" "$PACKAGER" install -y curl
            curl -fsSL https://raw.githubusercontent.com/imputnet/helium-linux/main/pubkey.asc | "$ESCALATION_TOOL" gpg --dearmor -o /usr/share/keyrings/helium.gpg
            echo "deb [signed-by=/usr/share/keyrings/helium.gpg] https://pkg.helium.computer/deb stable main" | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/helium.list
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y helium-bin
        ;;
        *)
            printf "%b\n" "${RED}Helium doesn't support ${PACKAGER}${RC}"
            ;;
        esac
    else
        printf "%b\n" "${GREEN}Helium Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installHeliumBrowser
