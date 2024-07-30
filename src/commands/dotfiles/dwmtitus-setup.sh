#!/bin/sh -e

setupDWM() {
    echo "Installing DWM-Titus if not already installed"
    if ! command_exists dwm; then
        case "$PACKAGER" in
            pacman)
                sudo "$PACKAGER" -S --noconfirm --needed base-devel libx11 libxinerama libxft imlib2
                ;;
            *)
                sudo "$PACKAGER" install -y build-essential libx11-dev libxinerama-dev libxft-dev libimblib2-dev
                ;;
        esac
    else
        echo "DWM is already installed."
    fi
   cd $HOME && git clone https://github.com/ChrisTitusTech/dwm-titus.git
   cd dwm-titus/
   sudo ./setup.sh
   sudo make clean install
}

checkEnv
setupDWM
