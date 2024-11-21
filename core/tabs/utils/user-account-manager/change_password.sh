#!/bin/sh -e

# shellcheck disable=SC1091
. ./user-manager-functions.sh

changePassword() {
    clear
    printf "%b\n" "${YELLOW}Change password${RC}"
    printf "%b\n" "${YELLOW}=================${RC}"

    printf "%b" "${YELLOW}Enter the username: ${RC}"
    read -r username

    checkEmpty "$username"

    if id "$username" >/dev/null 2>&1; then
        printf "%b" "${YELLOW}Enter new password: ${RC}"
        read -r password

        printf "%b" "${YELLOW}Are you sure you want to change password for ""$username""? [Y/n]: ${RC}"
        read -r confirm
        confirmAction "$confirm"

        echo "$username:$password" | "$ESCALATION_TOOL" chpasswd
        printf "%b\n" "${GREEN}Password changed successfully${RC}"
    else
        printf "%b\n" "${RED}User $username does not exist.${RC}"
        exit 1
    fi
}

changePassword
