#!/bin/sh -e

. ../../common-script.sh

upgradeAlpine() {
    printf "%b\n" "${YELLOW}Backing up repositories file...${RC}"
    "$ESCALATION_TOOL" cp /etc/apk/repositories /etc/apk/repositories.backup

    printf "%b\n" "${YELLOW}Choose Alpine version:${RC}"
    printf "%b\n" "${CYAN}1) Latest Stable${RC}"
    printf "%b\n" "${CYAN}2) Edge (rolling)${RC}"
    printf "%b" "Enter your choice (1 or 2): "
    read -r choice

    case $choice in
        1)
            printf "%b\n" "${YELLOW}Updating repositories to latest stable...${RC}"
            "$ESCALATION_TOOL" sh -c 'cat > /etc/apk/repositories << EOF
https://dl-cdn.alpinelinux.org/alpine/latest-stable/main
https://dl-cdn.alpinelinux.org/alpine/latest-stable/community
EOF'
            ;;
        2)
            printf "%b\n" "${YELLOW}Updating repositories to edge...${RC}"
            "$ESCALATION_TOOL" sh -c 'cat > /etc/apk/repositories << EOF
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF'
            ;;
        *)
            printf "%b\n" "${RED}Invalid choice. Exiting...${RC}"
            exit 1
            ;;
    esac

    printf "%b\n" "${YELLOW}Updating package index...${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" update

    printf "%b\n" "${YELLOW}Upgrading all packages...${RC}"
    "$ESCALATION_TOOL" "$PACKAGER" upgrade --available

    printf "%b\n" "${GREEN}Upgrade completed!${RC}"
    printf "%b\n" "${YELLOW}Note: If you encounter any issues, you can restore your previous repositories file from /etc/apk/repositories.backup${RC}"
}

checkEnv
upgradeAlpine 