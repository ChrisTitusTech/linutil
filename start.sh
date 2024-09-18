#!/bin/sh

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
        *) check 1 "Unsupported architecture"
    esac
}

get_latest_release() {
  curl --silent "https://api.github.com/repos/harshav167/linutil/releases/latest" | 
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

getUrl() {
    local latest_release=$(get_latest_release)
    echo "https://github.com/harshav167/linutil/releases/download/$latest_release/linutil"
}

findArch
temp_file=$(mktemp)
check $? "Creating the temporary file"

curl -fsL "$(getUrl)" -o "$temp_file"
check $? "Downloading linutil"

chmod +x "$temp_file"
check $? "Making linutil executable"

"$temp_file"
check $? "Executing linutil"

rm -f "$temp_file"
check $? "Deleting the temporary file"
