#!/bin/sh -e

. ../../common-script.sh

multimedia() {
    case "$PACKAGER" in
        dnf)
            if [ -e /etc/yum.repos.d/rpmfusion-free.repo ] && [ -e /etc/yum.repos.d/rpmfusion-nonfree.repo ]; then
                printf "%b\n" "${YELLOW}Installing Multimedia Codecs...${RC}"
                "$ESCALATION_TOOL" "$PACKAGER" swap ffmpeg-free ffmpeg --allowerasing -y
                printf "%b\n" "${GREEN}Multimedia Codecs Installed...${RC}"
            else
                printf "%b\n" "${RED}RPM Fusion repositories not found. Please set up RPM Fusion first!${RC}"
            fi
            ;;
        *)
            printf "%b\n" "${RED}Unsupported distribution: $DTYPE${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
multimedia