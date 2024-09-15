#!/bin/sh -e

. ../common-script.sh

mainMenu() {
    while true; do
        clear
        printf "%b\n" "${YELLOW}User Control Panel${RC}"
        printf "%b\n" "${YELLOW}=================${RC}"
        echo "1. Create a new user"
        echo "2. Delete a user"
        echo "3. Modify a user"
        echo "0. Exit"
        read -e -p "Choose an option: " choice

        case "$choice" in
            1) createUser ;;
            2) deleteUser ;;
            3) modifyUser ;;
            0) exit 0 ;;
            *) printf "%b\n" "${RED}Invalid option. Please [Enter] to try again.${RC}"; read -r ;;
        esac
    done
}

createUser() {
    clear
    printf "%b\n" "${YELLOW}Create a new user${RC}"
    printf "%b\n" "${YELLOW}=================${RC}"
    read -e -p "Enter the username: " username

    # Check if username is empty
    if [ -z "$username" ]; then
        printf "%b\n" "${RED}Invalid username${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read -r
        return
    fi

    # Check if user already exists
    if id "$username" > /dev/null 2>&1; then
        printf "%b\n" "${RED}User already exists${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read -r
        return
    fi

    # Check if username is valid
    if ! echo "$username" | grep -Eq '^[a-z][-a-z0-9_]+$'; then
        printf "%b\n" "${RED}Username must only contain letters, numbers, hyphens, and underscores. It cannot start with a number or contain spaces.${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read -r
        return
    fi

    password=""
    password2=""

    promptPassword() {
        read -s -p "Enter the password: " password
        echo # Moves to a new line after the password input
        read -s -p "Re-enter the password: " password2
        echo # Moves to a new line after the password input

        if [ "$password" != "$password2" ]; then
            printf "%b\n" "${RED}Passwords do not match${RC}"
            printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
            read -r
            promptPassword
        fi
    }

    promptPassword

    $ESCALATION_TOOL useradd -m "$username" -g users -G wheel,audio,video -s /bin/bash
    echo "$username:$password" | $ESCALATION_TOOL chpasswd

    printf "%b\n" "${GREEN}User created successfully${RC}"
    printf "%b\n" "${GREEN}Press [Enter] to continue...${RC}"
    read -r
}

deleteUser() {
    clear
    printf "%b\n" "${YELLOW}Delete a user${RC}"
    printf "%b\n" "${YELLOW}=================${RC}"
    read -e -p "Enter the username: " username

    # Check if username is empty
    if [ -z "$username" ]; then
        printf "%b\n" "${RED}Invalid username${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read -r
        return
    fi

    # Check if system reserved user
    if [ "$(id -u "$username")" -le 999 ]; then
        printf "%b\n" "${RED}Cannot delete system users${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read -r
        return
    fi

    # Check if current user
    if [ "$username" = "$USER" ]; then
        printf "%b\n" "${RED}Cannot delete the current user${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read -r
        return
    fi

    # Check if valid user
    if ! id "$username" > /dev/null 2>&1; then
        printf "%b\n" "${RED}User does not exist${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read -r
        return
    fi

    $ESCALATION_TOOL userdel --remove "$username" 2>/dev/null
    printf "%b\n" "${GREEN}User deleted successfully${RC}"
    printf "%b\n" "${GREEN}Press [Enter] to continue...${RC}"
    read -r
}

modifyUser() {
    clear
    printf "%b\n" "${YELLOW}Modify a user${RC}"
    printf "%b\n" "${YELLOW}=================${RC}"
    read -e -p "Enter the username: " username

    # Check if username is empty
    if [ -z "$username" ]; then
        printf "%b\n" "${RED}Invalid username${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read -r
        return
    fi

    # Check if user exists
    if ! id "$username" > /dev/null 2>&1; then
        printf "%b\n" "${RED}User does not exist${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read -r
        return
    fi

    # Check if system reserved user
    if [ "$(id -u "$username")" -le 999 ] && [ "$(id -u "$username")" -ne 0 ]; then
        printf "%b\n" "${RED}Cannot modify system users${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read -r
        return
    fi

    while true; do
        clear
        printf "%b\n" "${YELLOW}Modifying user $username${RC}"
        printf "%b\n" "${YELLOW}=================${RC}"
        echo "1. Change password"
        echo "2. Add to group"
        echo "3. Remove from group"
        echo "0. Exit"
        read -e -p "Choose an option: " choice

        case "$choice" in
            1) changePassword "$username" ;;
            2) addToGroup "$username" ;;
            3) removeFromGroup "$username" ;;
            0) break ;;
            *) printf "%b\n" "${RED}Invalid option. Please [Enter] to try again.${RC}"; read -r ;;
        esac
    done
}

changePassword() {
    clear
    printf "%b\n" "${YELLOW}Change password${RC}"
    printf "%b\n" "${YELLOW}=================${RC}"
    password=""
    password2=""

    promptPassword() {
        read -s -p "Enter the password: " password
        echo # Moves to a new line after the password input
        read -s -p "Re-enter the password: " password2
        echo # Moves to a new line after the password input

        if [ "$password" != "$password2" ]; then
            printf "%b\n" "${RED}Passwords do not match${RC}"
            printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
            read -r
            promptPassword
        fi
    }

    promptPassword

    echo "$1:$password" | $ESCALATION_TOOL chpasswd
    printf "%b\n" "${GREEN}Password changed successfully${RC}"
    printf "%b\n" "${GREEN}Press [Enter] to continue...${RC}"
    read -r
}

addToGroup() {
    clear
    printf "%b\n" "${YELLOW}Add to group${RC}"
    printf "%b\n" "${YELLOW}=================${RC}"
    read -e -p "Enter the group name: " group

    # Check if group is empty
    if [ -z "$group" ]; then
        printf "%b\n" "${RED}Invalid group name${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read -r
        return
    fi

    # Check if group exists
    if ! getent group "$group" > /dev/null 2>&1; then
        printf "%b\n" "${RED}Group does not exist${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read -r
        return
    fi

    $ESCALATION_TOOL usermod -aG "$group" "$1"
    printf "%b\n" "${GREEN}User added to group successfully${RC}"
    printf "%b\n" "${GREEN}Press [Enter] to continue...${RC}"
    read -r
}

removeFromGroup() {
    clear
    printf "%b\n" "${YELLOW}Remove from group${RC}"
    printf "%b\n" "${YELLOW}=================${RC}"
    read -e -p "Enter the group name: " group

    # Check if group is empty
    if [ -z "$group" ]; then
        printf "%b\n" "${RED}Invalid group name${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read -r
        return
    fi

    # Check if group exists
    if ! getent group "$group" > /dev/null 2>&1; then
        printf "%b\n" "${RED}Group does not exist${RC}"
        printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
        read -r
        return
    fi

    $ESCALATION_TOOL gpasswd -d "$1" "$group"
    printf "%b\n" "${GREEN}User removed from group successfully${RC}"
    printf "%b\n" "${GREEN}Press [Enter] to continue...${RC}"
    read -r
}

checkEscalationTool
mainMenu
