#!/bin/sh -e

. ../../common-script.sh

installVivaldi() {
    if ! command_exists vivaldi; then
        printf "%b\n" "${YELLOW}Installing Vivaldi...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y curl
                "$ESCALATION_TOOL" curl -fsSL https://repo.vivaldi.com/archive/linux_signing_key.pub | gpg --dearmor | sudo dd of=/usr/share/keyrings/vivaldi-browser.gpg
                "$ESCALATION_TOOL" echo "deb [signed-by=/usr/share/keyrings/vivaldi-browser.gpg arch=$(dpkg --print-architecture)] https://repo.vivaldi.com/archive/deb/ stable main" | sudo dd of=/etc/apt/sources.list.d/vivaldi-archive.list
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y vivaldi-stable
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y dnf-plugins-core
                dnf_version=$(dnf --version | head -n 1 | cut -d '.' -f 1)
                if [ "$dnf_version" -eq 4 ]; then
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager --add-repo https://repo.vivaldi.com/stable/vivaldi-fedora.repo
                else
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager addrepo --from-repofile=https://repo.vivaldi.com/stable/vivaldi-fedora.repo
                fi
                "$ESCALATION_TOOL" "$PACKAGER" install -y vivaldi-stable
                ;;
            zypper)
                "$ESCALATION_TOOL" zypper ar https://repo.vivaldi.com/archive/vivaldi-suse.repo
                "$ESCALATION_TOOL" zypper --non-interactive --gpg-auto-import-keys in vivaldi-stable
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm vivaldi
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
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
