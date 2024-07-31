#!/bin/sh -e

. ./common-script.sh

setupDMENU() {
   echo "Install Dmenu, if not already installed..."
   if ! command_exists dmenu; then
      case ${PACKAGER} in
         pacman)
            # Dependencies
            sudo ${PACKAGER} -S --noconfirm dmenu
            ;;
         *)
            # Dependencies
            sudo ${PACKAGER} install -y dmenu
            ;;
         esac
   else
      echo "Dmenu is already installed."
   fi
}

checkEnv
setupDMENU
