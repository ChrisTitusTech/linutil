#!/bin/sh -e

. ../../common-script.sh

installThrorium() {
    if ! command_exists thorium-browser; then
        printf "%b\n" "${YELLOW}Installing Thorium Browser...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" rm -fv /etc/apt/sources.list.d/thorium.list
                "$ESCALATION_TOOL" curl http://dl.thorium.rocks/debian/dists/stable/thorium.list -o /etc/apt/sources.list.d/thorium.list
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y thorium-browser
                ;;
            zypper|dnf)
                url=$(curl -s https://api.github.com/repos/Alex313031/Thorium/releases/latest | grep -oP '(?<=browser_download_url": ")[^"]*\.rpm')
                echo "$url" && curl -L "$url" -o thorium-latest.rpm
                "$ESCALATION_TOOL" "$PACKAGER" install -y thorium-latest.rpm && rm thorium-latest.rpm
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm thorium-browser-bin
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Thorium Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installThrorium