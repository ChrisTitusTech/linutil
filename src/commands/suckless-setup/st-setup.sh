#!/bin/sh -e

. ./common-script.sh

setupST() {
   echo "Install ST, if not already installed..."
   if ! command_exists st; then
      case ${PACKAGER} in
         pacman)
            curl -S "https://dl.suckless.org/st/st-0.9.2.tar.gz" --output app-src/st.tar.gz
            tar -xvf app-src/st.tar.gz
            sudo make clean install -C app-src/st
            echo "Copying ST src code"
            sudo mkdir -p "$HOME/.local/share/st"
            cp -r app-src/dwm $HOME/.local/share/dwm
            cp -r app-src/st $HOME/.local/share/st
            echo "ST's src code is now in ~/.local/share/st"

            ;;
         *)
            curl -S "https://dl.suckless.org/st/st-0.9.2.tar.gz" --output app-src/st.tar.gz
            tar -xvf app-src/st.tar.gz
            sudo make clean install -C app-src/st
            echo "Copying ST src code"
            sudo mkdir -p "$HOME/.local/share/setup"
            sudo mkdir -p "$HOME/.local/share/setup/st"
            cp -r app-src/dwm $HOME/.local/share/dwm
            cp -r app-src/st $HOME/.local/share/st
            echo "ST's src code is now in ~/.local/share/setup/st"

            ;;
         esac
   else
      echo "ST is already installed."
   fi
}

checkEnv
setupST
