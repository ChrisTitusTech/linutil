#!/bin/sh -e

. ../../common-script.sh

installSublime() {
    if ! command_exists sublime; then
        printf "%b\n" "${YELLOW}Installing Sublime...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | elevated_execution apt-key add -
                echo "deb https://download.sublimetext.com/ apt/stable/" | elevated_execution tee /etc/apt/sources.list.d/sublime-text.list
                elevated_execution "$PACKAGER" update
                elevated_execution "$PACKAGER" install -y sublime-text
                ;;
            zypper)
                elevated_execution rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
                elevated_execution "$PACKAGER" addrepo -g -f https://download.sublimetext.com/rpm/dev/x86_64/sublime-text.repo
                elevated_execution "$PACKAGER" refresh
                elevated_execution "$PACKAGER" --non-interactive install sublime-text
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm sublime-text-4
                ;;
            dnf)
                elevated_execution rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
                elevated_execution "$PACKAGER" config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
                elevated_execution "$PACKAGER" install -y sublime-text
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
