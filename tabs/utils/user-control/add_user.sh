#!/bin/sh -e

. ./utility_functions.sh

printf "%b\n" "${YELLOW}Create a new user${RC}"
printf "%b\n" "${YELLOW}=================${RC}"
read -p "Enter the username: " username

# Check if username is empty
if ! checkEmpty "$username"; then return; fi

# Check if user already exists
if id "$username" > /dev/null 2>&1; then
    printf "%b\n" "${RED}User already exists${RC}"
    printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
    read dummy
    return
fi

# Check if username is valid
if ! echo "$username" | grep '^[a-z][-a-z0-9_]*$' > /dev/null; then
    printf "%b\n" "${RED}Username must only contain letters, numbers, hyphens, and underscores. It cannot start with a number or contain spaces.${RC}"
    printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
    read dummy
    return
fi

password=$(promptPassword)

$ESCALATION_TOOL useradd -m "$username" -g users -s /bin/bash
echo "$username:$password" | $ESCALATION_TOOL chpasswd

printf "%b\n" "${GREEN}User $username created successfully${RC}"
printf "%b\n" "${GREEN}To add additional groups use Change User Group${RC}"
printf "%b\n" "${GREEN}Press [Enter] to continue...${RC}"
read dummy
