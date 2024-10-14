#!/bin/sh -e

. ../common-script.sh

installDepend() {
    ## Check for dependencies.
    DEPENDENCIES='tar tree multitail tldr trash-cli unzip cmake make jq'
    printf "%b\n" "${YELLOW}Installing dependencies...${RC}"
    case "$PACKAGER" in
        pacman)
            if ! grep -q "^\s*\[multilib\]" /etc/pacman.conf; then
                echo "[multilib]" | elevated_execution tee -a /etc/pacman.conf
                echo "Include = /etc/pacman.d/mirrorlist" | elevated_execution tee -a /etc/pacman.conf
                elevated_execution "$PACKAGER" -Syu
            else
                printf "%b\n" "${GREEN}Multilib is already enabled.${RC}"
            fi
            "$AUR_HELPER" -S --needed --noconfirm $DEPENDENCIES
            ;;
        apt-get|nala)
            COMPILEDEPS='build-essential'
            elevated_execution "$PACKAGER" update
            elevated_execution dpkg --add-architecture i386
            elevated_execution "$PACKAGER" update
            elevated_execution "$PACKAGER" install -y $DEPENDENCIES $COMPILEDEPS
            ;;
        dnf)
            COMPILEDEPS='@development-tools'
            elevated_execution "$PACKAGER" update
            elevated_execution "$PACKAGER" config-manager --set-enabled powertools
            elevated_execution "$PACKAGER" install -y $DEPENDENCIES $COMPILEDEPS
            elevated_execution "$PACKAGER" install -y glibc-devel.i686 libgcc.i686
            ;;
        zypper)
            COMPILEDEPS='patterns-devel-base-devel_basis'
            elevated_execution "$PACKAGER" refresh 
            elevated_execution "$PACKAGER" --non-interactive install $DEPENDENCIES $COMPILEDEPS
            elevated_execution "$PACKAGER" --non-interactive install libgcc_s1-gcc7-32bit glibc-devel-32bit
            ;;
        *)
            elevated_execution "$PACKAGER" install -y $DEPENDENCIES
            ;;
    esac
}

checkEnv
checkAURHelper
checkEscalationTool
installDepend