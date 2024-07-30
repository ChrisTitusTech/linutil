#!/bin/sh -e

setupDWM() {
    echo "Installing DWM-Titus if not already installed"
    case "$PACKAGER" in # Install pre-Requisites
        pacman)
            sudo "$PACKAGER" -S --noconfirm --needed base-devel libx11 libxinerama libxft imlib2
            ;;
        *)
            sudo "$PACKAGER" install -y build-essential libx11-dev libxinerama-dev libxft-dev libimblib2-dev
            ;;
    esac
   cd $HOME && git clone https://github.com/ChrisTitusTech/dwm-titus.git # CD to Home directory to install dwm-titus
   # This path can be changed (e.g. to linux-toolbox directory)
   cd dwm-titus/ # Hardcoded path, maybe not the best.
   sudo ./setup.sh # Run setup
   sudo make clean install # Run make clean install
}

checkEnv
setupDWM
