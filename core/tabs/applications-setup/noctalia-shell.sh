#!/usr/bin/env sh

# shellcheck disable=SC2016
#
. ../common-script.sh
. ../common-service-script.sh

installNoctalia() {
    printf "%b\n" "${YELLOW}Installing Noctalia Shell...${RC}"

    if ! command_exists dms; then
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm --cleanafter noctalia-shell noctalia-qs
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
                "$ESCALATION_TOOL" "$PACKAGER" install -y noctalia-shell
                ;;
            apt-get|nala)
                curl -fsSL https://pkg.noctalia.dev/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/noctalia.gpg
                echo "deb [signed-by=/etc/apt/keyrings/noctalia.gpg] https://pkg.noctalia.dev/apt trixie main" | sudo tee /etc/apt/sources.list.d/noctalia.list
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y noctalia-shell
                ;;
            zypper)
                # Only needed for Leap
                "$ESCALATION_TOOL" "$PACKAGER" addrepo --refresh --name noctalia-legacy https://download.opensuse.org/repositories/home:neifua:Noctalia/16.0/home:neifua:Noctalia.repo

                "$ESCALATION_TOOL" "$PACKAGER" refresh
                "$ESCALATION_TOOL" "$PACKAGER" install -y noctalia-shell
                ;;
            *)
                printf "%b\n" "${RED}Unsupported Package Manager: $PACKAGER${RC}"
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Noctalia Shell already installed${RC}"
    fi

    printf "%b\n" "${GREEN}Noctalia Shell installation complete${RC}"
}

uninstallNoctalia() {
    printf "%b\n" "${YELLOW}Uninstalling Noctalia Shell...${RC}"

    if command_exists dms; then
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -Rns --noconfirm --cleanafter noctalia-shell noctalia-qs
                ;;
            apt-get|nala|dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" remove -y noctalia-shell
                ;;
            *)
                printf "%b\n" "${RED}Unsupported Package Manager: $PACKAGER${RC}"
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Noctalia Shell is not installed${RC}"
    fi

    printf "%b\n" "${GREEN}Noctalia Shell uninstall complete${RC}"
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Noctalia Shell${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installNoctalia ;;
        2) uninstallNoctalia ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
main
