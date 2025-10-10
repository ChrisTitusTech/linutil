#!/bin/sh -e
# shellcheck disable=SC2086

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
            "$ESCALATION_TOOL" "$PACKAGER" update -y
            if ! "$ESCALATION_TOOL" "$PACKAGER" config-manager --enable powertools 2>/dev/null; then
                "$ESCALATION_TOOL" "$PACKAGER" config-manager --enable crb 2>/dev/null || true
            fi
            "$ESCALATION_TOOL" "$PACKAGER" -y install $DEPENDENCIES
            if ! "$ESCALATION_TOOL" "$PACKAGER" -y group install "Development Tools" 2>/dev/null; then
                "$ESCALATION_TOOL" "$PACKAGER" -y group install development-tools
            fi
            "$ESCALATION_TOOL" "$PACKAGER" -y install glibc-devel.i686 libgcc.i686
            ;;
        zypper)
            COMPILEDEPS='patterns-devel-base-devel_basis'
            "$ESCALATION_TOOL" "$PACKAGER" refresh 
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install $COMPILEDEPS
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install tar tree multitail unzip cmake make jq libgcc_s1-gcc7-32bit glibc-devel-32bit
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add build-base multitail tar tree trash-cli unzip cmake jq
            ;;
        xbps-install)
            COMPILEDEPS='base-devel'
            "$ESCALATION_TOOL" "$PACKAGER" -Sy $DEPENDENCIES $COMPILEDEPS
            "$ESCALATION_TOOL" "$PACKAGER" -Sy void-repo-multilib
            "$ESCALATION_TOOL" "$PACKAGER" -Sy glibc-32bit gcc-multilib
            ;;
        eopkg)
            COMPILEDEPS='-c system.devel'
            "$ESCALATION_TOOL" "$PACKAGER" update-repo
            "$ESCALATION_TOOL" "$PACKAGER" install -y tar tree unzip cmake make jq
            "$ESCALATION_TOOL" "$PACKAGER" install -y $COMPILEDEPS
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
