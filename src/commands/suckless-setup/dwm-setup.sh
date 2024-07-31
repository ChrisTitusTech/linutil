#!/bin/sh -e

. ./common-script.sh

setupDWM() {
   echo "Install DWM, if not already installed..."
   if ! command_exists dwm; then
      case ${PACKAGER} in
         pacman)
            # Dependencies
            sudo ${PACKAGER} -S --noconfirm dmenu freetype2 libx11 libxft libxinerama
            curl -S "https://dl.suckless.org/st/st-0.9.2.tar.gz" --output app-src/st.tar.gz
            tar -xvf app-src/st.tar.gz
            sudo make clean install -C app-src/st
            # DWM
            curl -S "https://dl.suckless.org/dwm/dwm-6.5.tar.gz" --output app-src/dwm.tar.gz
            tar -xvf app-src/dwm.tar.gz
            sudo make clean install -C app-src/dwm
            echo "Copying DWM src code"
            sudo mkdir -p "$HOME/.local/share/dwm"
            sudo mkdir -p "$HOME/.local/share/st"
            cp -r app-src/dwm $HOME/.local/share/dwm
            cp -r app-src/st $HOME/.local/share/st
            echo "DWM's src code is now in ~/.local/share/dwm"
            ;;
         *)
            # Dependencies
            sudo ${PACKAGER} install -S dmenu libx11-dev libx11-xcb-dev libxcb-res0-dev libxinerama-dev libxft-dev libimlib2-dev
            curl -S "https://dl.suckless.org/st/st-0.9.2.tar.gz" --output app-src/st.tar.gz
            tar -xvf app-src/st.tar.gz
            sudo make clean install -C app-src/st
            # DWM
            curl -S "https://dl.suckless.org/dwm/dwm-6.5.tar.gz" --output app-src/dwm.tar.gz
            tar -xvf app-src/dwm.tar.gz
            sudo make clean install -C app-src/dwm
            echo "Copying DWM src code"
            sudo mkdir -p "$HOME/.local/share/setup"
            sudo mkdir -p "$HOME/.local/share/setup/dwm"
            sudo mkdir -p "$HOME/.local/share/setup/st"
            cp -r app-src/dwm $HOME/.local/share/dwm
            cp -r app-src/st $HOME/.local/share/st
            echo "DWM's src code is now in ~/.local/share/setup/dwm"
            ;;
         esac
   else
      echo "DWM is already installed."
   fi
}

checkEnv
setupDWM
