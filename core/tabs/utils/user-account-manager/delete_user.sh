#!/bin/sh -e

# shellcheck disable=SC1091
. ./user-manager-functions.sh

deleteUser() {
    clear
    printf "%b\n" "${YELLOW}Delete a user${RC}"
    printf "%b\n" "${YELLOW}=================${RC}"

    printf "%b" "${YELLOW}Enter the username: ${RC}"
    read -r username

    checkEmpty "$username"

    if id "$username" >/dev/null 2>&1; then
        printf "%b" "${YELLOW}Are you sure you want to delete user ""$username""? [Y/n]: ${RC}"
        read -r confirm
        confirmAction "$confirm"

        $ESCALATION_TOOL userdel --remove "$username" 2>/dev/null
        printf "%b\n" "${GREEN}User $username deleted successfully${RC}"
    else
        printf "%b\n" "${RED}User $username does not exist.${RC}"
        exit 1
    fi
}

deleteUser
