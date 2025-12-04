#!/bin/sh -e

. ../common-script.sh

installPodman() {
    if ! command_exists podman; then
        printf "%b\n" "${YELLOW}Installing Podman...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm --needed podman
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add podman
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy podman
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y podman
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Podman is already installed.${RC}"
    fi
}

addRegistry() {
    printf "\n%b\n" "${YELLOW}Do you want to add docker.io to the list of unqualified search registries?${RC}"
    printf "%b\n" "This allows using short names like 'postgres' instead of 'docker.io/library/postgres'. (y/n)${RC}"
    read -r answer
    if echo "$answer" | grep -qE '^[Yy]$'; then
        printf "%b\n" "${YELLOW}Adding docker.io to registries...${RC}"
        CONF_DIR="/etc/containers/registries.conf.d"
        CONF_FILE="$CONF_DIR/10-unqualified-search-registries.conf"
        REGISTRY_LINE='unqualified-search-registries = ["docker.io"]'

        if [ ! -d "$CONF_DIR" ]; then
            "$ESCALATION_TOOL" mkdir -p "$CONF_DIR"
        fi

        if ! grep -Fxq "$REGISTRY_LINE" "$CONF_FILE" 2>/dev/null; then
            printf "%s\n" "$REGISTRY_LINE" | "$ESCALATION_TOOL" tee -a "$CONF_FILE" > /dev/null
            printf "%b\n" "${GREEN}Successfully added docker.io to registries.${RC}"
        else
            printf "%b\n" "${YELLOW}docker.io already present in registries.${RC}"
        fi

        printf "%b\n" "${GREEN}Successfully added docker.io to registries.${RC}"
    else
        printf "%b\n" "${GREEN}Skipping registry addition.${RC}"
    fi
}

checkEnv
checkEscalationTool
installPodman
addRegistry
