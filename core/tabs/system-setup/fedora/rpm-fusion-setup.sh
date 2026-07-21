#!/bin/sh -e

. ../../common-script.sh

# https://rpmfusion.org/Configuration
FEDORA_VERSION=$(rpm -E %fedora)

installRPMFusion() {
    case "$PACKAGER" in
        dnf)
            if [ ! -e /etc/yum.repos.d/rpmfusion-free.repo ] || [ ! -e /etc/yum.repos.d/rpmfusion-nonfree.repo ]; then
                printf "%b\n" "${YELLOW}Installing RPM Fusion...${RC}"

                "$ESCALATION_TOOL" "$PACKAGER" install -y \
                    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$FEDORA_VERSION).noarch.rpm" \
                    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$FEDORA_VERSION.noarch.rpm"

                if [ "$FEDORA_VERSION" -ge 41 ]; then
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager setopt fedora-cisco-openh264.enabled=1
                else
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager --enable fedora-cisco-openh264
                fi

                "$ESCALATION_TOOL" "$PACKAGER" install -y rpmfusion-\*-appstream-data

            else
                printf "%b\n" "${GREEN}RPM Fusion already installed${RC}"
            fi
            ;;
        *)
            printf "%b\n" "${RED}Unsupported distribution: $DTYPE${RC}"
            ;;
    esac
}

installRPMFusionTainted() {
    case "$PACKAGER" in
        dnf)
            if ! rpm -q "rpmfusion-free-release-tainted" >/dev/null 2>&1 || ! rpm -q "rpmfusion-nonfree-release-tainted" >/dev/null 2>&1; then
                printf "%b\n" "${YELLOW}Do you want to install tainted repositories? [y/N]: ${RC}"
                read -r install_tainted

                case "$install_tainted" in
                    [Yy]*)
                        printf "%b\n" "${YELLOW}Installing RPM Fusion tainted repositories...${RC}"
                        "$ESCALATION_TOOL" "$PACKAGER" install -y rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted

                        if [ "$FEDORA_VERSION" -ge 41 ]; then
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
                printf "%b\n" "${GREEN}RPM Fusion Tainted already installed${RC}"
            fi
            ;;
        *)
            printf "%b\n" "${RED}Unsupported distribution: $DTYPE${RC}"
            ;;
    esac
}

checkEnv
installRPMFusion
installRPMFusionTainted
