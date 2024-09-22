#!/bin/sh -e

. ../../common-script.sh

installGithubDesktop() {
    if ! command_exists github-desktop; then
        printf "%b\n" "${YELLOW}Installing Github Desktop...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -fsSL https://apt.packages.shiftkey.dev/gpg.key | gpg --dearmor | "$ESCALATION_TOOL" tee /usr/share/keyrings/shiftkey-packages.gpg > /dev/null
                printf "%b\n" 'deb [arch=amd64 signed-by=/usr/share/keyrings/shiftkey-packages.gpg] https://apt.packages.shiftkey.dev/ubuntu/ any main\n' | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/shiftkey-packages.list > /dev/null
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y github-desktop
                ;;
            zypper)
                "$ESCALATION_TOOL" rpm --import https://rpm.packages.shiftkey.dev/gpg.key
                printf "%b\n" '[shiftkey-packages]\nname=GitHub Desktop\nbaseurl=https://rpm.packages.shiftkey.dev/rpm/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://rpm.packages.shiftkey.dev/gpg.key\n' | "$ESCALATION_TOOL" tee /etc/zypp/repos.d/shiftkey-packages.repo > /dev/null
                "$ESCALATION_TOOL" "$PACKAGER" refresh
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install github-desktop
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm github-desktop-bin
                ;;
            dnf)
                "$ESCALATION_TOOL" rpm --import https://rpm.packages.shiftkey.dev/gpg.key
                printf "%b\n" '[shiftkey-packages]\nname=GitHub Desktop\nbaseurl=https://rpm.packages.shiftkey.dev/rpm/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://rpm.packages.shiftkey.dev/gpg.key\n' | "$ESCALATION_TOOL" tee /etc/yum.repos.d/shiftkey-packages.repo > /dev/null
                "$ESCALATION_TOOL" "$PACKAGER" install -y github-desktop
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Github Desktop is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installGithubDesktop
