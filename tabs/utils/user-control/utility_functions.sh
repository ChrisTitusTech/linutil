#!/bin/sh -e

. ../../common-script.sh

promptPassword() {
    stty -echo
    read -p "Enter the password (PASSWORD IS HIDDEN): " password1
    echo >&2
    read -p "Re-enter the password (PASSWORD IS HIDDEN): " password2
    echo >&2
    stty echo

    if ! checkEmpty "$password1"; then
        promptPassword
    fi

    if [ "$password1" != "$password2" ]; then
        printf "%b\n" "${RED}Passwords do not match${RC}" >&2
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}" >&2
        read dummy
        promptPassword
    else
        echo $password1
    fi
}

checkEmpty() {
    if [ -z "$1" ]; then
        printf "%b\n" "${RED}Empty value is not allowed${RC}" >&2
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}" >&2
        read dummy
        return 1
    fi
}

checkReservedUsername() {
    if [ "$(id -u "$1")" -le 999 ] || [ "$2" = "root" ]; then
        printf "%b\n" "${RED}Cannot modify system users${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read dummy
        return 1
    fi
}

confirmAction() {
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        printf "%b\n" "${RED}Cancelled operation...${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read dummy
        return 1
    fi
}


checkEscalationTool
