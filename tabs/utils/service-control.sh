#!/bin/sh -e

# Load common script functions
. ../common-script.sh  

#external services directory 
SCRIPT_DIR="./services"

# Function to show the main menu
show_menu() {
    clear
    printf "============================\n"
    printf " Service Management Menu\n"
    printf "============================\n"
    printf "1. View all services\n"
    printf "2. View enabled services\n"
    printf "3. View disabled services\n"
    printf "4. Add a new service\n"
    printf "5. Remove a service\n"
    printf "6. Start a service\n"
    printf "7. Stop a service\n"
    printf "8. Enable a service\n"
    printf "9. Disable a service\n"
    printf "10. Create a service from external scripts\n"
    printf "11. Exit\n"
    printf "============================\n"
}

# Function to view all services
view_all_services() {
    printf "Listing all services...\n"
    $ESCALATION_TOOL systemctl list-units --type=service --all --no-legend | awk '{print $1}' | sed 's/\.service//' | more
}

# Function to view enabled services
view_enabled_services() {
    printf "Listing enabled services...\n"
    $ESCALATION_TOOL systemctl list-unit-files --type=service --state=enabled --no-legend | awk '{print $1}' | sed 's/\.service//' | more
}

# Function to view disabled services
view_disabled_services() {
    printf "Listing disabled services...\n"
    $ESCALATION_TOOL systemctl list-unit-files --type=service --state=disabled --no-legend | awk '{print $1}' | sed 's/\.service//' | more
}

# Function to view started services
view_started_services() {
    printf "Listing started services:\n"
    $ESCALATION_TOOL systemctl list-units --type=service --state=running --no-pager | head -n -6 | awk 'NR>1 {print $1}' | more
}

# Function to add a new service
add_service() {
    while [ -z "$SERVICE_NAME" ]; do
        printf "Enter the name of the new service (e.g., my_service):\n"
        read -r SERVICE_NAME

        if $ESCALATION_TOOL systemctl list-units --type=service --all --no-legend | grep -q "$SERVICE_NAME.service"; then
            printf "Service already exists!\n"
            SERVICE_NAME=""
        fi
    done

    printf "Enter the description of the service:\n"
    read -r SERVICE_DESCRIPTION

    printf "Enter the command to execute the service (e.g., /usr/local/bin/my_service.sh):\n"
    read -r EXEC_START

    printf "Enter the user to run the service as (leave empty for default):\n"
    read -r SERVICE_USER

    printf "Enter the working directory for the service (leave empty for default):\n"
    read -r WORKING_DIRECTORY

    printf "Enter the restart policy (e.g., always, on-failure; leave empty for no restart):\n"
    read -r RESTART_POLICY

    # Create the service unit file
    SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
    
    # Create the service file with conditionals for optional fields
    {
        printf "[Unit]\n"
        printf "Description=$SERVICE_DESCRIPTION\n"
        printf "\n"
        printf "[Service]\n"
        printf "ExecStart=$EXEC_START\n"
        [ -n "$SERVICE_USER" ] && printf "User=$SERVICE_USER\n"
        [ -n "$WORKING_DIRECTORY" ] && printf "WorkingDirectory=$WORKING_DIRECTORY\n"
        [ -n "$RESTART_POLICY" ] && printf "Restart=$RESTART_POLICY\n"
        printf "\n"
        printf "[Install]\n"
        printf "WantedBy=multi-user.target\n"
    } | $ESCALATION_TOOL tee "$SERVICE_FILE" > /dev/null

    # Set permissions and reload systemd
    $ESCALATION_TOOL chmod 644 "$SERVICE_FILE"
    $ESCALATION_TOOL systemctl daemon-reload
    printf "Service $SERVICE_NAME has been created and is ready to be started.\n"

    # Optionally, enable and start the service
    printf "Do you want to start and enable the service now? (y/n)\n"
    read -r START_ENABLE

    if [ "$START_ENABLE" = "y" ]; then
        $ESCALATION_TOOL systemctl start "$SERVICE_NAME"
        $ESCALATION_TOOL systemctl enable "$SERVICE_NAME"
        printf "Service $SERVICE_NAME has been started and enabled.\n"
    else
        printf "Service $SERVICE_NAME has been created but not started.\n"
    fi
}

# Function to remove a service
remove_service() {
    printf "Enter the name of the service to remove (e.g., my_service):\n"
    read -r SERVICE_NAME

    SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

    if [ -f "$SERVICE_FILE" ]; then
        printf "Stopping and disabling the service...\n"
        $ESCALATION_TOOL systemctl stop "$SERVICE_NAME"
        $ESCALATION_TOOL systemctl disable "$SERVICE_NAME"

        printf "Removing the service file...\n"
        $ESCALATION_TOOL rm -f "$SERVICE_FILE"
        $ESCALATION_TOOL systemctl daemon-reload

        printf "Service $SERVICE_NAME has been removed.\n"
    else
        printf "Service $SERVICE_NAME does not exist.\n"
    fi
}

# Function to start a service
start_service() {
    view_disabled_services
    printf "Enter the name of the service to start (e.g., my_service):\n"
    read -r SERVICE_NAME

    if $ESCALATION_TOOL systemctl start "$SERVICE_NAME"; then
        printf "Service $SERVICE_NAME has been started.\n"
    else
        printf "Failed to start service: $SERVICE_NAME.\n"
    fi
}

# Function to stop a service
stop_service() {
    view_started_services
    printf "Enter the name of the service to stop (e.g., my_service):\n"
    read -r SERVICE_NAME

    if $ESCALATION_TOOL systemctl stop "$SERVICE_NAME"; then
        printf "Service $SERVICE_NAME has been stopped.\n"
    else
        printf "Failed to stop service: $SERVICE_NAME.\n"
    fi
}

# Function to enable a service
enable_service() {
    view_disabled_services
    printf "Enter the name of the service to enable (e.g., my_service):\n"
    read -r SERVICE_NAME

    if $ESCALATION_TOOL systemctl enable "$SERVICE_NAME"; then
        printf "Service $SERVICE_NAME has been enabled.\n"
    else
        printf "Failed to enable service: $SERVICE_NAME.\n"
    fi
}

# Function to enable a service
disable_service() {
    view_enabled_services
    printf "Enter the name of the service to disable (e.g., my_service):\n"
    read -r SERVICE_NAME

    if $ESCALATION_TOOL systemctl disable "$SERVICE_NAME"; then
        printf "Service $SERVICE_NAME has been enabled.\n"
    else
        printf "Failed to enable service: $SERVICE_NAME.\n"
    fi
}

# Function to create, start, and enable a service from an external service file
create_service_from_external() {

    # List all .service files in the SCRIPT_DIR
    printf "============================\n"
    printf "Listing available service files\n"
    printf "============================\n"
    for FILE in "$SCRIPT_DIR"/*.service; do
        printf "%s\n" "$(basename "$FILE")"
    done

    printf "Enter the filename (without the .service extension) of the service to create:\n"
    read -r SERVICE_NAME

    SERVICE_FILE="$SCRIPT_DIR/$SERVICE_NAME.service"

    if [ ! -f "$SERVICE_FILE" ]; then
        printf "Service file $SERVICE_FILE does not exist.\n"
        return
    fi

    printf "Enter the username to run the service as (leave empty for no specific user):\n"
    read -r SERVICE_USER

    # Create the systemd service file path
    SYSTEMD_SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

    # Add or update the User= line in the service file
    if [ -n "$SERVICE_USER" ]; then
        # Check if User= exists and append username if needed
        if grep -q '^User=' "$SERVICE_FILE"; then
            # Update the existing User= line with the new username
            sed -i "s/^User=.*/User=$SERVICE_USER/" "$SERVICE_FILE"
        else
            # Add the User= line if it doesn't exist
            sed -i '/^\[Service\]/a User='"$SERVICE_USER" "$SERVICE_FILE"
        fi
    fi

    # Copy the modified service file to /etc/systemd/system/
    $ESCALATION_TOOL cp "$SERVICE_FILE" "$SYSTEMD_SERVICE_FILE"

    # Set permissions and reload systemd
    $ESCALATION_TOOL chmod 644 "$SYSTEMD_SERVICE_FILE"
    $ESCALATION_TOOL systemctl daemon-reload
    printf "Service $SERVICE_NAME has been created and is ready to be started.\n"

    # Optionally, enable and start the service
    printf "Do you want to start and enable the service now? (y/n)\n"
    read -r START_ENABLE

    if [ "$START_ENABLE" = "y" ]; then
        $ESCALATION_TOOL systemctl start "$SERVICE_NAME"
        $ESCALATION_TOOL systemctl enable "$SERVICE_NAME"
        printf "Service $SERVICE_NAME has been started and enabled.\n"
    else
        printf "Service $SERVICE_NAME has been created but not started.\n"
    fi
}

main() {
    while true; do
        show_menu
        printf "Enter your choice:\n"
        read -r CHOICE

        case $CHOICE in
            1) view_all_services ;;
            2) view_enabled_services ;;
            3) view_disabled_services ;;
            4) add_service ;;
            5) remove_service ;;
            6) start_service ;;
            7) stop_service ;;
            8) enable_service ;;
            9) disable_service ;; 
            10) create_service_from_external ;;
            11) printf "Exiting...\n"; exit 0 ;;
            *) printf "Invalid choice. Please try again.\n" ;;
        esac

        printf "Press [Enter] to continue...\n"
        read -r dummy
    done
}

checkEnv
checkEscalationTool
main