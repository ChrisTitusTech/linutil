#!/bin/sh -e

. ../../common-script.sh

installMeld() {
    cd "$HOME" && git clone https://gitlab.gnome.org/GNOME/meld.git
    echo "PATH=\$PATH:$HOME/meld/bin" | "$ESCALATION_TOOL" tee -a /etc/environment
}

checkEnv
checkEscalationTool
installMeld
