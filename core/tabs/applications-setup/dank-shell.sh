#!/usr/bin/env sh

. ../common-script.sh
. ../common-service-script.sh

installDank() {
    printf "%b\n" "${YELLOW}Installing Dank Shell...${RC}"

    if ! command_exists dms; then
        curl -fsSL https://install.danklinux.com | sh
    else
        printf "%b\n" "${GREEN}Dank Shell already installed${RC}"
    fi

}

uninstallDank() {
    printf "%b\n" "${YELLOW}Uninstalling Dank Shell...${RC}"

    if command_exists dms; then
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -Rns --noconfirm --cleanafter dms-shell greetd-dms-greeter-git
                ;;
            apt-get|nala|dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" remove -y dms
                ;;
            *)
                printf "%b\n" "${RED}Unsupported Package Manager: $PACKAGER${RC}"
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Dank Shell is not installed${RC}"
    fi

}

main() {
    installDank
}

checkEnv
main
