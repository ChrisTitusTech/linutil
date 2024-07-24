#!/bin/sh

RC='\033[0m'
RED='\033[0;31m'

temp_file=$1

# Function to check command exit status and print error message if failed
check() {
    local exit_code=$1
    local message=$2

    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}ERROR: $message${RC}"
        exit 1
    fi
}

# Use patchelf to execute linutil on NixOS
nix-shell -p patchelf -p glibc --run "
patchelf --set-interpreter $(nix-build --no-out-link '<nixpkgs>' -A glibc)/lib/ld-linux-x86-64.so.2 --set-rpath /run/current-system/sw/lib $temp_file
"
check $? "Patching linutil"

$temp_file
check $? "Executing linutil"
