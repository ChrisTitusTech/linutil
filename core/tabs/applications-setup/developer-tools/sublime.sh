#!/bin/sh -e

. ../../common-script.sh

installSublime() {
    if ! command_exists sublime; then
        printf "%b\n" "${YELLOW}Installing Sublime...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | "$ESCALATION_TOOL" apt-key add -
                echo "deb https://download.sublimetext.com/ apt/stable/" | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/sublime-text.list
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y sublime-text
                ;;
            zypper)
                "$ESCALATION_TOOL" rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
                "$ESCALATION_TOOL" "$PACKAGER" addrepo -g -f https://download.sublimetext.com/rpm/dev/x86_64/sublime-text.repo
                "$ESCALATION_TOOL" "$PACKAGER" refresh
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install sublime-text
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm sublime-text-4
                ;;
            dnf)
                "$ESCALATION_TOOL" rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
                dnf_version=$(dnf --version | head -n 1 | cut -d '.' -f 1)
                if [ "$dnf_version" -eq 4 ]; then
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager --add-repo https://download.sublimetext.com/rpm/dev/x86_64/sublime-text.repo
                else
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager addrepo --from-repofile=https://download.sublimetext.com/rpm/dev/x86_64/sublime-text.repo
                fi
                "$ESCALATION_TOOL" "$PACKAGER" install -y sublime-text
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Sublime is already installed.${RC}"
    fi

}

checkEnv
checkEscalationTool
installSublime
