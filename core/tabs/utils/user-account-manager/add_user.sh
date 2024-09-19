#!/bin/sh -e

. ../../common-script.sh
. ./utility_functions.sh

clear
printf "%b\n" "${YELLOW}Create a new user${RC}"
printf "%b\n" "${YELLOW}=================${RC}"

username=$(promptUsername "add" "non-root") || exit 1

# Check if username is valid
if ! echo "$username" | grep '^[a-z][-a-z0-9_]*$' > /dev/null; then
    printf "%b\n" "${RED}Username must only contain letters, numbers, hyphens, and underscores. It cannot start with a number or contain spaces.${RC}"
    exit 1
fi

password=$(promptPassword) || exit 1

$ESCALATION_TOOL useradd -m "$username" -g users -s /bin/bash
echo "$username:$password" | "$ESCALATION_TOOL" chpasswd

printf "%b\n" "${GREEN}User $username created successfully${RC}"
printf "%b\n" "${GREEN}To add additional groups use Add User To Groups${RC}"

checkEnv
