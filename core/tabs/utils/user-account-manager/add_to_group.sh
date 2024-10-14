#!/bin/sh -e

. ../../common-script.sh

. ../utility_functions.sh

addToGroup() {
    clear
    printf "%b\n" "${YELLOW}Add to group${RC}"
    printf "%b\n" "${YELLOW}=================${RC}"

    printf "%b" "${YELLOW}Enter the username: ${RC}"
    read -r username
    user_groups=$(groups "$username" | cut -d: -f2 | sort | tr '\n' ' ')

    printf "%b\n" "${YELLOW}Groups user $username is in:${RC} $user_groups"
    printf "%b\n" "${YELLOW}=================${RC}"

    available_groups=$(cut -d: -f1 /etc/group | sort | tr '\n' ' ')

    printf "%b\n" "${YELLOW}Available groups:${RC} $available_groups"
    printf "%b\n" "${YELLOW}=================${RC}"

    printf "%b" "${YELLOW}Enter the groups you want to add user $username to (space-separated): ${RC}"
    read -r groups

    checkEmpty "$groups" || exit 1
    if ! checkGroups "$groups" "$available_groups"; then
        printf "%b\n" "${RED}One or more groups are not available.${RC}"
        exit 1
    fi

    groups_to_add=$(echo "$groups" | tr ' ' ',')

    printf "%b" "${YELLOW}Are you sure you want to add user $username to $groups_to_add? [Y/n]: ${RC}"
    read -r confirm
    confirmAction || exit 1

    elevated_execution usermod -aG "$groups_to_add" "$username"

    printf "%b\n" "${GREEN}User successfully added to the $groups_to_add${RC}"
}

checkEnv
checkEscalationTool
checkGroups
addToGroup