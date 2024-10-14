#!/bin/sh -e

. ../../common-script.sh

# https://rpmfusion.org/Configuration

installRPMFusion() {
    case "$PACKAGER" in
        dnf)
            if [ ! -e /etc/yum.repos.d/rpmfusion-free.repo ] || [ ! -e /etc/yum.repos.d/rpmfusion-nonfree.repo ]; then
                printf "%b\n" "${YELLOW}Installing RPM Fusion...${RC}"
                elevated_execution "$PACKAGER" install "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
                elevated_execution "$PACKAGER" config-manager --enable fedora-cisco-openh264
                elevated_execution "$PACKAGER" config-manager --set-enabled rpmfusion-nonfree-updates
                elevated_execution "$PACKAGER" config-manager --set-enabled rpmfusion-free-updates
                printf "%b\n" "${GREEN}RPM Fusion installed and enabled${RC}"
            else
                printf "%b\n" "${GREEN}RPM Fusion already installed${RC}"
            fi
            ;;
        *)
            printf "%b\n" "${RED}Unsupported distribution: $DTYPE${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
installRPMFusion