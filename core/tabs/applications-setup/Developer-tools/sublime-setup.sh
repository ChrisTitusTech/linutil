#!/bin/sh -e

. ../../common-script.sh

installSublime() {
	if ! command_exists sublime; then
            printf "%b\n" "${YELLOW}Installing Sublime...${RC}"
            case "$PACKAGER" in
                apt-get)
                    curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | "$ESCALATION_TOOL" apt-key add -
                    echo "deb https://download.sublimetext.com/ apt/stable/" | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/sublime-text.list
                    "$ESCALATION_TOOL" "$PACKAGER" install sublime-text
                    ;;
                zypper)
                    "$ESCALATION_TOOL" rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
                    "$ESCALATION_TOOL" "$PACKAGER" addrepo -g -f https://download.sublimetext.com/rpm/dev/x86_64/sublime-text.repo
                    "$ESCALATION_TOOL" "$PACKAGER" install sublime-text
                    ;;
                pacman)
                    curl -O https://download.sublimetext.com/sublimehq-pub.gpg && "$ESCALATION_TOOL" pacman-key --add sublimehq-pub.gpg && "$ESCALATION_TOOL" pacman-key --lsign-key 8A8F901A && rm sublimehq-pub.gpg
                    printf "%b\n" '[sublime-text]\nServer = https://download.sublimetext.com/arch/stable/x86_64' | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
                    "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm sublime-text
                    ;;
                dnf)
                    "$ESCALATION_TOOL" rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
                    "$ESCALATION_TOOL" "$PACKAGER" install sublime-text
                    ;;
                *)
                    printf "%b\n" "${RED}The script does not support your Distro. Install manually..${RC}"
                    ;;
            esac
        else
            printf "%b\n" "${GREEN}Sublime is already installed.${RC}"
        fi

}

checkEnv
checkEscalationTool
installSublime
