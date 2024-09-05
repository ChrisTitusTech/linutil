#!/bin/sh -e

. ../common-script.sh

installDepend() {
    ## Check for dependencies.
    DEPENDENCIES='tar tree multitail tldr trash-cli unzip cmake make jq'
    echo -e "${YELLOW}Installing dependencies...${RC}"
    case $PACKAGER in
        pacman)
            if ! grep -q "^\s*\[multilib\]" /etc/pacman.conf; then
                echo "[multilib]" | $ESCALATION_TOOL tee -a /etc/pacman.conf
                echo "Include = /etc/pacman.d/mirrorlist" | $ESCALATION_TOOL tee -a /etc/pacman.conf
                $ESCALATION_TOOL "$PACKAGER" -Syu
            else
                echo "Multilib is already enabled."
            fi
            if ! command_exists yay && ! command_exists paru; then
                echo "Installing yay as AUR helper..."
                $ESCALATION_TOOL "$PACKAGER" -S --needed --noconfirm base-devel
                cd /opt && $ESCALATION_TOOL git clone https://aur.archlinux.org/yay-git.git && $ESCALATION_TOOL chown -R "$USER":"$USER" ./yay-git
                cd yay-git && makepkg --noconfirm -si
            else
                echo "Aur helper already installed"
            fi
            if command_exists yay; then
                AUR_HELPER="yay"
            elif command_exists paru; then
                AUR_HELPER="paru"
            else
                echo "No AUR helper found. Please install yay or paru."
                exit 1
            fi
            $AUR_HELPER -S --needed --noconfirm "$DEPENDENCIES"
            ;;
        apt-get|nala)
            COMPILEDEPS='build-essential'
            $ESCALATION_TOOL "$PACKAGER" update
            $ESCALATION_TOOL dpkg --add-architecture i386
            $ESCALATION_TOOL "$PACKAGER" update
            $ESCALATION_TOOL "$PACKAGER" install -y $DEPENDENCIES $COMPILEDEPS 
            ;;
        dnf)
            COMPILEDEPS='@development-tools'
            $ESCALATION_TOOL "$PACKAGER" update
            $ESCALATION_TOOL "$PACKAGER" config-manager --set-enabled powertools
            $ESCALATION_TOOL "$PACKAGER" install -y "$DEPENDENCIES" $COMPILEDEPS
            $ESCALATION_TOOL "$PACKAGER" install -y glibc-devel.i686 libgcc.i686
            ;;
        zypper)
            COMPILEDEPS='patterns-devel-base-devel_basis'
            $ESCALATION_TOOL "$PACKAGER" refresh 
            $ESCALATION_TOOL "$PACKAGER" --non-interactive install "$DEPENDENCIES" $COMPILEDEPS
            $ESCALATION_TOOL "$PACKAGER" --non-interactive install libgcc_s1-gcc7-32bit glibc-devel-32bit
            ;;
        *)
            $ESCALATION_TOOL "$PACKAGER" install -y $DEPENDENCIES # Fixed bug where no packages found on debian-based
            ;;
    esac
}

install_additional_dependencies() {
    case $(command -v apt || command -v zypper || command -v dnf || command -v pacman) in
        *apt)
            # Add additional dependencies for apt if needed
            ;;
        *zypper)
            # Add additional dependencies for zypper if needed
            ;;
        *dnf)
            # Add additional dependencies for dnf if needed
            ;;
        *pacman)
            # Add additional dependencies for pacman if needed
            ;;
        *)
            # Add additional dependencies for other package managers if needed
            ;;
    esac
}

checkEnv
checkEscalationTool
installDepend
install_additional_dependencies
