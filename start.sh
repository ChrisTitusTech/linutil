#!/bin/sh

RC='\033[0m'
RED='\033[0;31m'

linutil="https://github.com/ChrisTitusTech/linutil/releases/latest/download/linutil"

PACKAGER=""
DTYPE=""

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
        echo -e "${RED}ERROR: $message${RC}"
        exit 1
    fi
}

checkEnv

TMPFILE=$(mktemp)
check $? "Creating the temporary file"

curl -fsL $linutil -o $TMPFILE
check $? "Downloading linutil"

chmod +x $TMPFILE
check $? "Making linutil executable"

PKGR="$PACKAGER" DT="$DTYPE" "$TMPFILE"
check $? "Executing linutil"

rm -f $TMPFILE
check $? "Deleting the temporary file"
