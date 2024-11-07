#!/bin/sh -e

# Prevent execution if this script was only partially downloaded
{
rc='\033[0m'
red='\033[0;31m'

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

findArch() {
    case "$(uname -m)" in
        x86_64|amd64) arch="x86_64" ;;
        aarch64|arm64) arch="aarch64" ;;
        *) check 1 "Unsupported architecture"
    esac
}

getUrl() {
    case "${arch}" in
        x86_64) echo "https://github.com/ChrisTitusTech/linutil/releases/latest/download/linutil";;
        *) echo "https://github.com/ChrisTitusTech/linutil/releases/latest/download/linutil-${arch}";;
    esac
}

findArch
temp_file=$(mktemp)
check $? "Creating the temporary file"

curl -fsL "$(getUrl)" -o "$temp_file"
check $? "Downloading linutil"

chmod +x "$temp_file"
check $? "Making linutil executable"

"$temp_file" "$@"
check $? "Executing linutil"

rm -f "$temp_file"
check $? "Deleting the temporary file"
} # End of wrapping
