#!/bin/sh -e

# Load common script functions
. ../common-script.sh  

#external services directory 
SCRIPT_DIR="./services"

# Function to show the main menu
show_menu() {
    clear
    echo "============================"
    echo " Service Management Menu"
    echo "============================"
    echo "1. View all services"
    echo "2. View enabled services"
    echo "3. View disabled services"
    echo "4. Add a new service"
    echo "5. Remove a service"
    echo "6. Start a service"
    echo "7. Stop a service"
    echo "8. Enable a service"
    echo "9. Disable a service"
    echo "10. Create a service from external scripts"
    echo "11. Exit"
    echo "============================"
}

# Function to view all services
view_all_services() {
    echo "Listing all services..."
    $ESCALATION_TOOL systemctl list-units --type=service --all --no-legend | awk '{print $1}' | sed 's/\.service//' | more
}

# Function to view enabled services
view_enabled_services() {
    echo "Listing enabled services..."
    $ESCALATION_TOOL systemctl list-unit-files --type=service --state=enabled --no-legend | awk '{print $1}' | sed 's/\.service//' | more
}

# Function to view disabled services
view_disabled_services() {
    echo "Listing disabled services..."
    $ESCALATION_TOOL systemctl list-unit-files --type=service --state=disabled --no-legend | awk '{print $1}' | sed 's/\.service//' | more
}

# Function to view started services
view_started_services() {
    echo "Listing started services:"
    $ESCALATION_TOOL systemctl list-units --type=service --state=running --no-pager | head -n -6 | awk 'NR>1 {print $1}' | more
}

# Function to add a new service
add_service() {
    while [ -z "$SERVICE_NAME" ]; do
        echo "Enter the name of the new service (e.g., my_service):"
        read -r SERVICE_NAME

        if $ESCALATION_TOOL systemctl list-units --type=service --all --no-legend | grep -q "$SERVICE_NAME.service"; then
            echo "Service already exists!"
            SERVICE_NAME=""
        fi
    done

    echo "Enter the description of the service:"
    read -r SERVICE_DESCRIPTION

    echo "Enter the command to execute the service (e.g., /usr/local/bin/my_service.sh):"
    read -r EXEC_START

    echo "Enter the user to run the service as (leave empty for default):"
    read -r SERVICE_USER

    echo "Enter the working directory for the service (leave empty for default):"
    read -r WORKING_DIRECTORY

    echo "Enter the restart policy (e.g., always, on-failure; leave empty for no restart):"
    read -r RESTART_POLICY

    # Create the service unit file
    SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
    
    # Create the service file with conditionals for optional fields
    {
        echo "[Unit]"
        echo "Description=$SERVICE_DESCRIPTION"
        echo ""
        echo "[Service]"
        echo "ExecStart=$EXEC_START"
        [ -n "$SERVICE_USER" ] && echo "User=$SERVICE_USER"
        [ -n "$WORKING_DIRECTORY" ] && echo "WorkingDirectory=$WORKING_DIRECTORY"
        [ -n "$RESTART_POLICY" ] && echo "Restart=$RESTART_POLICY"
        echo ""
        echo "[Install]"
        echo "WantedBy=multi-user.target"
    } | $ESCALATION_TOOL tee "$SERVICE_FILE" > /dev/null

    # Set permissions and reload systemd
    $ESCALATION_TOOL chmod 644 "$SERVICE_FILE"
    $ESCALATION_TOOL systemctl daemon-reload
    echo "Service $SERVICE_NAME has been created and is ready to be started."

    # Optionally, enable and start the service
    echo "Do you want to start and enable the service now? (y/n)"
    read -r START_ENABLE

    if [ "$START_ENABLE" = "y" ]; then
        $ESCALATION_TOOL systemctl start "$SERVICE_NAME"
        $ESCALATION_TOOL systemctl enable "$SERVICE_NAME"
        echo "Service $SERVICE_NAME has been started and enabled."
    else
        echo "Service $SERVICE_NAME has been created but not started."
    fi
}

# Function to remove a service
remove_service() {
    echo "Enter the name of the service to remove (e.g., my_service):"
    read -r SERVICE_NAME

    SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

    if [ -f "$SERVICE_FILE" ]; then
        echo "Stopping and disabling the service..."
        $ESCALATION_TOOL systemctl stop "$SERVICE_NAME"
        $ESCALATION_TOOL systemctl disable "$SERVICE_NAME"

        echo "Removing the service file..."
        $ESCALATION_TOOL rm -f "$SERVICE_FILE"
        $ESCALATION_TOOL systemctl daemon-reload

        echo "Service $SERVICE_NAME has been removed."
    else
        echo "Service $SERVICE_NAME does not exist."
    fi
}

# Function to start a service
start_service() {
    view_disabled_services
    echo "Enter the name of the service to start (e.g., my_service):"
    read -r SERVICE_NAME

    if $ESCALATION_TOOL systemctl start "$SERVICE_NAME"; then
        echo "Service $SERVICE_NAME has been started."
    else
        echo "Failed to start service: $SERVICE_NAME."
    fi
}

# Function to stop a service
stop_service() {
    view_started_services
    echo "Enter the name of the service to stop (e.g., my_service):"
    read -r SERVICE_NAME

    if $ESCALATION_TOOL systemctl stop "$SERVICE_NAME"; then
        echo "Service $SERVICE_NAME has been stopped."
    else
        echo "Failed to stop service: $SERVICE_NAME."
    fi
}

# Function to enable a service
enable_service() {
    view_disabled_services
    echo "Enter the name of the service to enable (e.g., my_service):"
    read -r SERVICE_NAME

    if $ESCALATION_TOOL systemctl enable "$SERVICE_NAME"; then
        echo "Service $SERVICE_NAME has been enabled."
    else
        echo "Failed to enable service: $SERVICE_NAME."
    fi
}

# Function to enable a service
disable_service() {
    view_enabled_services
    echo "Enter the name of the service to disable (e.g., my_service):"
    read -r SERVICE_NAME

    if $ESCALATION_TOOL systemctl disable "$SERVICE_NAME"; then
        echo "Service $SERVICE_NAME has been enabled."
    else
        echo "Failed to enable service: $SERVICE_NAME."
    fi
}

# Function to create, start, and enable a service from an external service file
create_service_from_external() {

    # List all .service files in the SCRIPT_DIR
    echo "============================"
    echo "Listing available service files"
    echo "============================"
    for FILE in "$SCRIPT_DIR"/*.service; do
        echo "$(basename "$FILE")"
    done

    echo "Enter the filename (without the .service extension) of the service to create:"
    read -r SERVICE_NAME

    SERVICE_FILE="$SCRIPT_DIR/$SERVICE_NAME.service"

    if [ ! -f "$SERVICE_FILE" ]; then
        echo "Service file $SERVICE_FILE does not exist."
        return
    fi

    echo "Enter the username to run the service as (leave empty for no specific user):"
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
    echo "Service $SERVICE_NAME has been created and is ready to be started."

    # Optionally, enable and start the service
    echo "Do you want to start and enable the service now? (y/n)"
    read -r START_ENABLE

    if [ "$START_ENABLE" = "y" ]; then
        $ESCALATION_TOOL systemctl start "$SERVICE_NAME"
        $ESCALATION_TOOL systemctl enable "$SERVICE_NAME"
        echo "Service $SERVICE_NAME has been started and enabled."
    else
        echo "Service $SERVICE_NAME has been created but not started."
    fi
}

main() {
    while true; do
        show_menu
        echo "Enter your choice:"
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
            11) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid choice. Please try again." ;;
        esac

        echo "Press [Enter] to continue..."
        read -r dummy
    done
}

checkEnv
checkEscalationTool
main