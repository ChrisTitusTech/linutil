#!/bin/sh -e

. ../../common-script.sh

# Prompt for username
promptUsername() {
    printf "Enter the username: "
    read -r username

    checkEmpty "$username";
    
    if [ "$1" = "add" ]; then
        checkUserExistence "$username" "$1"
    else
        checkUserExistence "$username" "$1"
        checkReservedUsername "$username" "$2"
    fi
    echo "$username"
}


# Prompt for password
promptPassword() {
    stty -echo
    printf "Enter the password (PASSWORD IS HIDDEN): "
    read -r password1
    echo >&2
    printf "Re-enter the password (PASSWORD IS HIDDEN): "
    read -r password2
    echo >&2
    stty echo

    if ! checkEmpty "$password1"; then
        promptPassword
    fi

    if [ "$password1" != "$password2" ]; then
        printf "%b\n" "${RED}Passwords do not match${RC}" >&2
        promptPassword
    else
        echo $password1
    fi
}

# Check if input is empty
checkEmpty() {
    if [ -z "$1" ]; then
        printf "%b\n" "${RED}Empty value is not allowed${RC}" >&2
        exit 1
    fi
}

# Check if user exists
checkUserExistence() {
    if [ "$2" = "add" ]; then
        if id "$1" > /dev/null 2>&1; then
            printf "%b\n" "${RED}User already exists${RC}" >&2
            exit 1
        fi
    else
        if ! id "$1" > /dev/null 2>&1; then
            printf "%b\n" "${RED}User does not exist${RC}" >&2
            exit 1
        fi
    fi
}

# Check if user is reserved
checkReservedUsername() {
    uid=$(id -u "$1")
    if [ "$2" = "root" ]; then
        if [ "$uid" -le 999 ] && [ "$uid" -ne 0 ]; then
            printf "%b\n" "${RED}Cannot modify system users${RC}" >&2
            exit 1
        fi
    else 
        if [ "$(id -u "$1")" -le 999 ]; then
            printf "%b\n" "${RED}Cannot modify system users${RC}" >&2
            exit 1
        fi
    fi
}

# Check if user is reserved
confirmAction() {
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        printf "%b\n" "${RED}Cancelled operation...${RC}" >&2
        exit 1
    fi
}

# Check if group is available
checkGroupAvailabe() {
    for group in $1; do
        if ! echo "$2" | grep -wq "$group"; then
            printf "%b\n" "${RED}Group $group not avaiable${RC}" >&2
            exit 1
        fi
    done
}

checkEnv
checkEscalationTool
