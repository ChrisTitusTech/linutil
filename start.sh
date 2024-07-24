#!/bin/sh

rc='\033[0m'
red='\033[0;31m'

binary_url="https://github.com/ChrisTitusTech/linutil/releases/latest/download/linutil"

check() {
    exit_code=$1
    message=$2

    if [ "$exit_code" -ne 0 ]; then
        printf '%sERROR: %s%s\n' "$red" "$message" "$rc"
        exit 1
    fi

	unset exit_code
	unset message
}

temp_file=$(mktemp)
check $? "Creating the temporary file"

curl -fsL "$binary_url" -o "$temp_file"
check $? "Downloading linutil"

chmod +x "$temp_file"
check $? "Making linutil executable"

#if the script is being run on NixOS
if [ -f /etc/NIXOS ]; then
    ./nixos_start.sh "$temp_file"
    check $? "Executing linutil on NixOS"
else
    "$temp_file"
    check $? "Executing linutil"
fi

rm -f "$temp_file"
check $? "Deleting the temporary file"
