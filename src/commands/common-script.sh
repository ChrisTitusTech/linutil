#!/bin/bash -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

command_exists() {
    which "$1" >/dev/null 2>&1
}


checkCommandRequirements() {
    ## Check for requirements.
    REQUIREMENTS=$1
    for req in ${REQUIREMENTS}; do
        if ! command_exists "${req}"; then
            echo "${RED}To run me, you need: ${REQUIREMENTS}${RC}"
            exit 1
        fi
    done
}

checkPackageManager() {
    ## Check Package Manager
    PACKAGEMANAGER=$1
    for pgm in ${PACKAGEMANAGER}; do
        if command_exists "${pgm}"; then
            PACKAGER=${pgm}
            echo "Using ${pgm}"
            break
        fi
    done

    if [ -z "${PACKAGER}" ]; then
        echo "${RED}Can't find a supported package manager${RC}"
        exit 1
    fi
}

checkSuperUser() {
    ## Check SuperUser Group
    SUPERUSERGROUP='wheel sudo root'
    for sug in ${SUPERUSERGROUP}; do
        if groups | grep -q "${sug}"; then
            SUGROUP=${sug}
            echo "Super user group ${SUGROUP}"
            break
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep -q "${SUGROUP}"; then
        echo "${RED}You need to be a member of the sudo group to run me!${RC}"
        exit 1
    fi
}

checkCurrentDirectoryWritable() {
    ## Check if the current directory is writable.
    GITPATH="$(dirname "$(realpath "$0")")"
    if [ ! -w "$GITPATH" ]; then
        echo "${RED}Can't write to $GITPATH${RC}"
        exit 1
    fi
}

checkDistro() {
    DTYPE="unknown"  # Default to unknown
    # Use /etc/os-release for modern distro identification
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DTYPE=$ID
    fi
}

checkEnv() {
    checkCommandRequirements 'curl groups sudo'
    checkPackageHandler 'apt-get dnf pacman zypper'
    checkSuperUser
    checkDistro
}
