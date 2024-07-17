#!/bin/sh

RC='\033[0m'
RED='\033[0;31m'

ISLOCAL=false

# Function to fetch the latest release tag from the GitHub API
get_latest_release() {
  local latest_release
  latest_release=$(curl -s https://api.github.com/repos/ChrisTitusTech/linutil/releases | jq -r 'map(select(.prerelease == true)) | .tag_name')
  if [ -z "$latest_release" ]; then
    echo "Error fetching release data" >&2
    return 1
  fi
  echo "$latest_release"
}

# Function to redirect to the latest pre-release version
redirect_to_latest_pre_release() {
  local latest_release
  latest_release=$(get_latest_release)
  if [ -n "$latest_release" ]; then
    url="https://raw.githubusercontent.com/ChrisTitusTech/linutil/$latest_release/linutil"
  else
    echo 'Unable to determine latest pre-release version.' >&2
    echo "Using latest Full Release"
    url="https://github.com/ChrisTitusTech/linutil/releases/latest/download/linutil"
  fi
  echo "Using URL: $url"  # Log the URL being used
}

PACKAGER=""
DTYPE=""

command_exists() {
    which "$1" >/dev/null 2>&1
}

checkEnv() {
    ## Check for requirements.
    REQUIREMENTS='curl groups sudo'
    for req in $REQUIREMENTS; do
        if ! command_exists "$req"; then
            printf "${RED}To run me, you need: %s${RC}\n" "$REQUIREMENTS"
            exit 1
        fi
    done

    ## Check Package Handler
    PACKAGEMANAGER='apt-get dnf pacman zypper'
    for pgm in $PACKAGEMANAGER; do
        if command_exists "$pgm"; then
            PACKAGER="$pgm"
            printf "Using %s\n" "$pgm"
            break
        fi
    done

    if [ -z "$PACKAGER" ]; then
        printf "${RED}Can't find a supported package manager${RC}\n"
        exit 1
    fi

    ## Check SuperUser Group
    SUPERUSERGROUP='wheel sudo root'
    for sug in $SUPERUSERGROUP; do
        if groups | grep -q "$sug"; then
            SUGROUP="$sug"
            printf "Super user group %s\n" "$SUGROUP"
            break
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep -q "$SUGROUP"; then
        printf "${RED}You need to be a member of the sudo group to run me!${RC}\n"
        exit 1
    fi

    DTYPE="unknown"  # Default to unknown
    # Use /etc/os-release for modern distro identification
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DTYPE="$ID"
    fi
}

check() {
    local exit_code=$1
    local message=$2

    if [ $exit_code -ne 0 ]; then
        echo "${RED}ERROR: $message${RC}"
        exit 1
    fi
}

checkEnv

if [[ "$ISLOCAL" == "true" ]]; then
    PKGR="$PACKAGER" DT="$DTYPE" cargo run
else
    redirect_to_latest_pre_release

    TMPFILE=$(mktemp)
    check $? "Creating the temporary file"

    echo "Downloading linutil from $url"  # Log the download attempt
    curl -fsL $url -o $TMPFILE
    check $? "Downloading linutil"

    chmod +x $TMPFILE
    check $? "Making linutil executable"

    PKGR="$PACKAGER-start" DT="$DTYPE-start" "$TMPFILE"
    check $? "Executing linutil"

    rm -f $TMPFILE
    check $? "Deleting the temporary file"
fi
