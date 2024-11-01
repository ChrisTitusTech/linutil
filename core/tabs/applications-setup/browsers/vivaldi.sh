#!/bin/sh -e

. ../../common-script.sh

installVivaldi() {
    if ! command_exists vivaldi; then
        printf "%b\n" "${YELLOW}Installing Vivaldi...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                elevated_execution "$PACKAGER" install -y curl
                elevated_execution curl -fsSL https://repo.vivaldi.com/archive/linux_signing_key.pub | gpg --dearmor | sudo dd of=/usr/share/keyrings/vivaldi-browser.gpg
                elevated_execution echo "deb [signed-by=/usr/share/keyrings/vivaldi-browser.gpg arch=$(dpkg --print-architecture)] https://repo.vivaldi.com/archive/deb/ stable main" | sudo dd of=/etc/apt/sources.list.d/vivaldi-archive.list
                elevated_execution "$PACKAGER" update
                elevated_execution "$PACKAGER" install -y vivaldi-stable
                ;;
            dnf)
                elevated_execution "$PACKAGER" install -y dnf-plugins-core
                elevated_execution "$PACKAGER" config-manager --add-repo https://repo.vivaldi.com/stable/vivaldi-fedora.repo
                elevated_execution "$PACKAGER" install -y vivaldi-stable
                ;;
            zypper)
                elevated_execution zypper ar https://repo.vivaldi.com/archive/vivaldi-suse.repo
                elevated_execution zypper --non-interactive --gpg-auto-import-keys in vivaldi-stable
                ;;
            pacman)
                elevated_execution "$PACKAGER" -S --needed --noconfirm vivaldi
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Vivaldi Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installVivaldi
