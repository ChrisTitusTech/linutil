#!/bin/sh
RC='\033[0m'
RED='\033[0;31m'

# Function to check and install patchelf if not already installed for nix distro
install_patchelf() {
    if ! command -v patchelf > /dev/null; then
        echo "Installing patchelf..."
        nix-env -iA nixpkgs.patchelf
        if [ $? -ne 0 ]; then
            echo "${RED}ERROR: Failed to install patchelf.${RC}"
            exit 1
        fi
    else
        echo "patchelf is already installed."
    fi
}

# run  main script
run_main_script() {
    
    RC='\033[0m'
    RED='\033[0;31m'

    linutil="https://github.com/ChrisTitusTech/linutil/releases/latest/download/linutil"

    check() {
        local exit_code=$1
        local message=$2

        if [ $exit_code -ne 0 ]; then
            echo "${RED}ERROR: $message${RC}"
            exit 1
        fi
    }

    TMPFILE=$(mktemp)
    check $? "Creating the temporary file"

    curl -fsL $linutil -o $TMPFILE
    check $? "Downloading linutil"

    chmod +x $TMPFILE
    check $? "Making linutil executable"

    #patchelf to execute start.sh for NixOS
    nix-shell -p patchelf -p glibc --run "
    patchelf --set-interpreter $(nix-build --no-out-link '<nixpkgs>' -A glibc)/lib/ld-linux-x86-64.so.2 --set-rpath /run/current-system/sw/lib $TMPFILE
    "
    check $? "Patching linutil"

    $TMPFILE
    check $? "Executing linutil"

    rm -f $TMPFILE
    check $? "Deleting the temporary file"
}


install_patchelf 
run_main_script

