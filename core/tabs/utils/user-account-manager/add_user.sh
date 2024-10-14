#!/bin/sh -e

. ../../common-script.sh

. ../utility_functions.sh

createUser() {
    clear
    printf "%b\n" "${YELLOW}Create a new user${RC}"
    printf "%b\n" "${YELLOW}=================${RC}"
    printf "%b" "${YELLOW}Enter the username: ${RC}"
    read -r username

    if ! echo "$username" | grep '^[a-zA-Z]*$' > /dev/null; then
        printf "%b\n" "${RED}Username must only contain letters and cannot contain spaces.${RC}"
        exit 1
    fi

    printf "%b" "${YELLOW}Enter the password: ${RC}"
    read -r password
    printf "%b" "${YELLOW}Enter the password again: ${RC}"
    read -r password_confirmation

    if [ "$password" != "$password_confirmation" ]; then
        printf "%b\n" "${RED}Passwords do not match${RC}"
        exit 1
    fi

    elevated_execution useradd -m "$username" -g users -s /bin/bash
    echo "$username:$password" | elevated_execution chpasswd

    printf "%b\n" "${GREEN}User $username created successfully${RC}"
    printf "%b\n" "${GREEN}To add additional groups use Add User To Groups${RC}"
}

checkEnv
checkEscalationTool
createUser
