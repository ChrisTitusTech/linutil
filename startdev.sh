#!/bin/sh -e

# Prevent execution if this script was only partially downloaded
{
RC='\033[0m'
RED='\033[0;31m'

# Function to fetch the latest release tag from the GitHub API
get_latest_release() {
  latest_release=$(curl -s https://api.github.com/repos/ChrisTitusTech/linutil/releases | 
    grep -oP '"tag_name": "\K[^"]*' | 
    head -n 1)
  if [ -z "$latest_release" ]; then
    printf "%b\n" "Error fetching release data" >&2
    return 1
  fi
  printf "%b\n" "$latest_release"
}

# Function to redirect to the latest pre-release version
redirect_to_latest_pre_release() {
  latest_release=$(get_latest_release)
  if [ -n "$latest_release" ]; then
    url="https://github.com/ChrisTitusTech/linutil/releases/download/$latest_release/linutil"
  else
    printf "%b\n" 'Unable to determine latest pre-release version.' >&2
    printf "%b\n" "Using latest Full Release"
    url="https://github.com/ChrisTitusTech/linutil/releases/latest/download/linutil"
  fi
  addArch
  printf "%b\n" "Using URL: $url"
}

check() {
    exit_code=$1
    message=$2

    if [ "$exit_code" -ne 0 ]; then
        printf "%b\n" "${RED}ERROR: $message${RC}"
        exit 1
    fi
}

addArch() {
    case "${arch}" in
        x86_64);;
        *) url="${url}-${arch}";;
    esac
}

findArch() {
    case "$(uname -m)" in
        x86_64|amd64) arch="x86_64" ;;
        aarch64|arm64) arch="aarch64" ;;
        *) check 1 "Unsupported architecture"
    esac
}

findArch
redirect_to_latest_pre_release

TMPFILE=$(mktemp)
check $? "Creating the temporary file"

printf "%b\n" "Downloading linutil from $url"
curl -fsL "$url" -o "$TMPFILE"
check $? "Downloading linutil"

chmod +x "$TMPFILE"
check $? "Making linutil executable"

"$TMPFILE" "$@"
check $? "Executing linutil"

rm -f "$TMPFILE"
check $? "Deleting the temporary file"
} # End of wrapping
