#!/bin/sh -e

# Load common script functions
. ../common-script.sh  

#external services directory 
SCRIPT_DIR="./services"

# Function to show the main menu
show_menu() {
    clear
    printf "%b\n" "============================"
    printf "%b\n" "Service Management Menu"
    printf "%b\n" "============================"
    printf "%b\n" "1. View all services"
    printf "%b\n" "2. View enabled services"
    printf "%b\n" "3. View disabled services"
    printf "%b\n" "4. Add a new service"
    printf "%b\n" "5. Remove a service"
    printf "%b\n" "6. Start a service"
    printf "%b\n" "7. Stop a service"
    printf "%b\n" "8. Enable a service"
    printf "%b\n" "9. Disable a service"
    printf "%b\n" "10. Create a service from external scripts"
    printf "%b\n" "11. Exit"
    printf "%b\n" "============================"
}

# Function to view all services
view_all_services() {
    printf "%b\n" "Listing all services..."
    elevated_execution systemctl list-units --type=service --all --no-legend | awk '{print $1}' | sed 's/\.service//' | more
}

# Function to view enabled services
view_enabled_services() {
    printf "%b\n" "Listing enabled services..."
    elevated_execution systemctl list-unit-files --type=service --state=enabled --no-legend | awk '{print $1}' | sed 's/\.service//' | more
}

# Function to view disabled services
view_disabled_services() {
    printf "%b\n" "Listing disabled services..."
    elevated_execution systemctl list-unit-files --type=service --state=disabled --no-legend | awk '{print $1}' | sed 's/\.service//' | more
}

# Function to view started services
view_started_services() {
    printf "%b\n" "Listing started services: "
    elevated_execution systemctl list-units --type=service --state=running --no-pager | head -n -6 | awk 'NR>1 {print $1}' | more
}

# Function to add a new service
add_service() {
    while [ -z "$SERVICE_NAME" ]; do
        printf "%b" "Enter the name of the new service (e.g., my_service): "
        read -r SERVICE_NAME
        if elevated_execution systemctl list-units --type=service --all --no-legend | grep -q "$SERVICE_NAME.service"; then
            printf "%b\n" "${GREEN}Service already exists.${RC}"
            SERVICE_NAME=""
        fi
    done

    printf "%b" "Enter the description of the service: "
    read -r SERVICE_DESCRIPTION

    printf "%b" "Enter the command to execute the service (e.g., /usr/local/bin/my_service.sh): "
    read -r EXEC_START

    printf "%b" "Enter the user to run the service as (leave empty for default): "
    read -r SERVICE_USER

    printf "%b" "Enter the working directory for the service (leave empty for default): "
    read -r WORKING_DIRECTORY

    printf "%b" "Enter the restart policy (e.g., always, on-failure; leave empty for no restart): "
    read -r RESTART_POLICY

    # Create the service unit file
    SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
    
    # Create the service file with conditionals for optional fields
    {
        printf "%b\n" "[Unit]"
        printf "%b\n" "Description=$SERVICE_DESCRIPTION"
        printf "\n"
        printf "%b\n" "[Service]"
        printf "%b\n" "ExecStart=$EXEC_START"
        [ -n "$SERVICE_USER" ] && printf "%b\n" "User=$SERVICE_USER"
        [ -n "$WORKING_DIRECTORY" ] && printf "%b\n"  "WorkingDirectory=$WORKING_DIRECTORY"
        [ -n "$RESTART_POLICY" ] && printf "%b\n" "Restart=$RESTART_POLICY"
        printf "\n"
        printf "%b\n" "[Install]"
        printf "%b\n" "WantedBy=multi-user.target"
    } | elevated_execution tee "$SERVICE_FILE" > /dev/null

    # Set permissions and reload systemd
    elevated_execution chmod 644 "$SERVICE_FILE"
    elevated_execution systemctl daemon-reload
    printf "%b\n" "Service $SERVICE_NAME has been created and is ready to be started."

    # Optionally, enable and start the service
    printf "%b" "Do you want to start and enable the service now? (y/N): "
    read -r START_ENABLE

    if [ "$START_ENABLE" = "y" ] || [ "$START_ENABLE" = "Y" ]; then
        elevated_execution systemctl start "$SERVICE_NAME"
        elevated_execution systemctl enable "$SERVICE_NAME"
        printf "%b\n" "Service $SERVICE_NAME has been started and enabled."
    else
        printf "%b\n" "Service $SERVICE_NAME has been created but not started."
    fi
}

# Function to remove a service
remove_service() {
    printf "%b" "Enter the name of the service to remove (e.g., my_service): "
    read -r SERVICE_NAME

    SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

    if [ -f "$SERVICE_FILE" ]; then
        printf "%b\n" "Stopping and disabling the service..."
        elevated_execution systemctl stop "$SERVICE_NAME"
        elevated_execution systemctl disable "$SERVICE_NAME"

        printf "%b\n" "Removing the service file..."
        elevated_execution rm -f "$SERVICE_FILE"
        elevated_execution systemctl daemon-reload
        printf "%b\n" "Service $SERVICE_NAME has been removed."
    else
        printf "%b\n" "Service $SERVICE_NAME does not exist."
    fi
}

# Function to start a service
start_service() {
    view_disabled_services
    printf "%b" "Enter the name of the service to start (e.g., my_service): "
    read -r SERVICE_NAME

    if elevated_execution systemctl start "$SERVICE_NAME"; then
        printf "%b\n" "Service $SERVICE_NAME has been started."
    else
        printf "%b\n" "Failed to start service: $SERVICE_NAME."
    fi
}

# Function to stop a service
stop_service() {
    view_started_services
    printf "%b" "Enter the name of the service to stop (e.g., my_service): "
    read -r SERVICE_NAME

    if elevated_execution systemctl stop "$SERVICE_NAME"; then
        printf "%b\n" "Service $SERVICE_NAME has been stopped."
    else
        printf "%b\n" "Failed to stop service: $SERVICE_NAME."
    fi
}

# Function to enable a service
enable_service() {
    view_disabled_services
    printf "%b" "Enter the name of the service to enable (e.g., my_service): "
    read -r SERVICE_NAME

    if elevated_execution systemctl enable "$SERVICE_NAME"; then
        printf "%b\n" "Service $SERVICE_NAME has been enabled."
    else
        printf "%b\n" "Failed to enable service: $SERVICE_NAME."
    fi
}

# Function to enable a service
disable_service() {
    view_enabled_services
    printf "%b" "Enter the name of the service to disable (e.g., my_service): "
    read -r SERVICE_NAME

    if elevated_execution systemctl disable "$SERVICE_NAME"; then
        printf "%b\n" "Service $SERVICE_NAME has been enabled."
    else
        printf "%b\n" "Failed to enable service: $SERVICE_NAME."
    fi
}

# Function to create, start, and enable a service from an external service file
create_service_from_external() {

    # List all .service files in the SCRIPT_DIR
    printf "%b\n" "============================"
    printf "%b\n" "Listing available service files"
    printf "%b\n" "============================"
    for FILE in "$SCRIPT_DIR"/*.service; do
        printf "%b\n" "$(basename "$FILE")"
    done

    printf "%b" "Enter the filename (without the .service extension) of the service to create: "
    read -r SERVICE_NAME

    SERVICE_FILE="$SCRIPT_DIR/$SERVICE_NAME.service"

    if [ ! -f "$SERVICE_FILE" ]; then
        printf "%b\n" "Service file $SERVICE_FILE does not exist."
        return
    fi

    printf "%b" "Enter the username to run the service as (leave empty for no specific user): "
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
    elevated_execution cp "$SERVICE_FILE" "$SYSTEMD_SERVICE_FILE"

    # Set permissions and reload systemd
    elevated_execution chmod 644 "$SYSTEMD_SERVICE_FILE"
    elevated_execution systemctl daemon-reload
    printf "%b\n" "Service $SERVICE_NAME has been created and is ready to be started."

    # Optionally, enable and start the service
    printf "%b" "Do you want to start and enable the service now? (Y/n)"
    read -r START_ENABLE

    if [ "$START_ENABLE" = "y" ]; then
        elevated_execution systemctl start "$SERVICE_NAME"
        elevated_execution systemctl enable "$SERVICE_NAME"
        printf "%b\n" "Service $SERVICE_NAME has been started and enabled."
    else
        printf "%b\n" "Service $SERVICE_NAME has been created but not started."
    fi
}

main() {
    while true; do
        show_menu
        printf "%b" "Enter your choice: "
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
            11) printf "%b\n" "Exiting..."; exit 0 ;;
            *) printf "%b\n" "Invalid choice. Please try again." ;;
        esac

        printf "%b\n" "Press [Enter] to continue..."
        read -r dummy
    done
}

checkEnv
checkEscalationTool
main