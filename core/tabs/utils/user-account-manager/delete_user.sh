#!/bin/sh -e

. ../../common-script.sh

. ../utility_functions.sh

deleteUser() {
    clear
    printf "%b\n" "${YELLOW}Delete a user${RC}"
    printf "%b\n" "${YELLOW}=================${RC}"

    printf "%b" "${YELLOW}Enter the username: ${RC}"
    read -r username

    if id "$username" > /dev/null 2>&1; then
        printf "%b" "${YELLOW}Are you sure you want to delete user ""$username""? [Y/n]: ${RC}"
        read -r _
        confirmAction || exit 1

        $ESCALATION_TOOL userdel --remove "$username" 2>/dev/null
        printf "%b\n" "${GREEN}User $username deleted successfully${RC}"
    else
        printf "%b\n" "${RED}User $username does not exist.${RC}"
        exit 1
    fi
}

checkEnv
checkEscalationTool
deleteUser
