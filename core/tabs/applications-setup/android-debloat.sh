#!/bin/sh -e

. ../common-script.sh

install_adb() {
    if ! command_exists adb ; then
        printf "%b\n" "${YELLOW}Installing ADB...${RC}."
        case "$PACKAGER" in
            apt-get|nala)
                elevated_execution "$PACKAGER" install -y android-sdk-platform-tools
                ;;
            pacman)
                elevated_execution "$PACKAGER" -S --noconfirm android-tools
                ;;
            dnf|zypper)
                elevated_execution "$PACKAGER" install -y android-tools
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: "$PACKAGER"${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}ADB is already installed.${RC}"
    fi
}

install_universal_android_debloater() {
    if ! command_exists uad; then
        printf "%b\n" "${YELLOW}Installing Universal Android Debloater...${RC}."
        curl -sSLo "${HOME}/uad" "https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/releases/download/v1.1.0/uad-ng-linux"
        elevated_execution chmod +x "${HOME}/uad"
        elevated_execution mv "${HOME}/uad" /usr/local/bin/uad
    else
        printf "%b\n" "${GREEN}Universal Android Debloater is already installed. Run 'uad' command to execute.${RC}"
    fi
}                   

checkEnv
checkEscalationTool
install_adb
install_universal_android_debloater 
