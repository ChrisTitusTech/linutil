#!/bin/sh -e

. ../common-script.sh

installDepend() {
    ## Check for dependencies.
    DEPENDENCIES='tar tree multitail tldr trash-cli unzip cmake make jq'
    printf "%b\n" "${YELLOW}Installing dependencies...${RC}"
    case "$PACKAGER" in
        pacman)
            if ! grep -q "^\s*\[multilib\]" /etc/pacman.conf; then
                echo "[multilib]" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
                echo "Include = /etc/pacman.d/mirrorlist" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
                "$ESCALATION_TOOL" "$PACKAGER" -Syu
            else
                printf "%b\n" "${GREEN}Multilib is already enabled.${RC}"
            fi
            "$AUR_HELPER" -S --needed --noconfirm $DEPENDENCIES
            ;;
        apt-get|nala)
            COMPILEDEPS='build-essential'
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" dpkg --add-architecture i386
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y $DEPENDENCIES $COMPILEDEPS
            ;;
        dnf)
            COMPILEDEPS='@development-tools'
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled powertools
            "$ESCALATION_TOOL" "$PACKAGER" install -y $DEPENDENCIES $COMPILEDEPS
            "$ESCALATION_TOOL" "$PACKAGER" install -y glibc-devel.i686 libgcc.i686
            ;;
        zypper)
            COMPILEDEPS='patterns-devel-base-devel_basis'
            "$ESCALATION_TOOL" "$PACKAGER" refresh 
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install $DEPENDENCIES $COMPILEDEPS
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install libgcc_s1-gcc7-32bit glibc-devel-32bit
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add build-base multitail tar tree trash-cli unzip cmake jq
            ;;
        *)
            "$ESCALATION_TOOL" "$PACKAGER" install -y $DEPENDENCIES
            ;;
    esac
}

checkEnv
checkAURHelper
checkEscalationTool
installDepend