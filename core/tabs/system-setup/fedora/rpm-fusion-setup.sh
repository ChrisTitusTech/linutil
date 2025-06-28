#!/bin/sh -e

. ../../common-script.sh

# https://rpmfusion.org/Configuration

installRPMFusion() {
    case "$PACKAGER" in
        dnf)
            if [ ! -e /etc/yum.repos.d/rpmfusion-free.repo ] || [ ! -e /etc/yum.repos.d/rpmfusion-nonfree.repo ]; then
                printf "%b\n" "${YELLOW}Installing RPM Fusion...${RC}"
                
                "$ESCALATION_TOOL" "$PACKAGER" install -y \
                    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
                    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
                
                fedora_version=$(rpm -E %fedora)
                if [ "$fedora_version" -ge 41 ]; then
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager setopt fedora-cisco-openh264.enabled=1
                else
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager --enable fedora-cisco-openh264
                fi
                
                "$ESCALATION_TOOL" "$PACKAGER" install -y rpmfusion-\*-appstream-data
                
                printf "%b\n" "${YELLOW}Do you want to install tainted repositories? [y/N]: ${RC}"
                read -r install_tainted
                case "$install_tainted" in
                    [Yy]*)
                        printf "%b\n" "${YELLOW}Installing RPM Fusion tainted repositories...${RC}"
                        "$ESCALATION_TOOL" "$PACKAGER" install -y rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted
                        
                        if [ "$fedora_version" -ge 41 ]; then
                            "$ESCALATION_TOOL" "$PACKAGER" config-manager setopt rpmfusion-free-tainted.enabled=1
                            "$ESCALATION_TOOL" "$PACKAGER" config-manager setopt rpmfusion-nonfree-tainted.enabled=1
                        else
                            "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled rpmfusion-free-tainted
                            "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled rpmfusion-nonfree-tainted
                        fi
                        printf "%b\n" "${GREEN}RPM Fusion (including tainted repositories) installed and enabled${RC}"
                        ;;
                    *)
                        printf "%b\n" "${BLUE}Skipping tainted repositories${RC}"
                        printf "%b\n" "${GREEN}RPM Fusion installed and enabled${RC}"
                        ;;
                esac
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