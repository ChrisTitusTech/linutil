#!/bin/sh -e

. ../../common-script.sh

multimedia() {
    case $PACKAGER in
        dnf)
            if [[ -e /etc/yum.repos.d/rpmfusion-free.repo && -e /etc/yum.repos.d/rpmfusion-nonfree.repo ]]; then
            echo "Installing Multimedia Codecs"
            $ESCALATION_TOOL "$PACKAGER" swap ffmpeg-free ffmpeg --allowerasing -y
            $ESCALATION_TOOL "$PACKAGER" update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
            $ESCALATION_TOOL "$PACKAGER" update @sound-and-video -y
            echo "Multimedia Codecs Installed"
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