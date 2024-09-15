#!/bin/sh -e

. "$(dirname "$0")/../../common-script.sh"

# https://rpmfusion.org/Configuration

installRPMFusion() {
    case $PACKAGER in
        dnf)
            if [[ ! -e /etc/yum.repos.d/rpmfusion-free.repo || ! -e /etc/yum.repos.d/rpmfusion-nonfree.repo ]]; then
                echo "Installing RPM Fusion..."
                $ESCALATION_TOOL "$PACKAGER" install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
                $ESCALATION_TOOL "$PACKAGER" config-manager --enable fedora-cisco-openh264
                echo "RPM Fusion installed"
            else
                echo "RPM Fusion already installed"
            fi
            ;;
        *)
            echo "Unsupported distribution: $DTYPE"
            ;;
    esac
}

# Not sure how to implement reverting rpm-fusion, I will look back into this in the future.
revertRpmFusionSetup() {
    echo "Reverting is not implemented for this script."
}

run() {
    checkEnv
    installRPMFusion
}

revert() {
    checkEnv
    revertRpmFusionSetup
}