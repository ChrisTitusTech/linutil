#!/bin/bash
# Creates a systemd service for Input Remapper, enables and starts it
# It is assumed that Input Remapper is already installed
# Work in progress

# Source pretty output definitions
source ./pretty-output.sh

# Create the systemd user service file
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/input-remapper.service" << EOF
[Unit]
Description=Input Remapper Service

[Service]
ExecStart=/usr/bin/input-remapper-service
Restart=always

[Install]
WantedBy=default.target
EOF

echo -e "${GREEN}${CHECK} Input Remapper service file created at $HOME/.config/systemd/user/input-remapper.service${NC}"

# Create autostart entry for the GUI
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/input-remapper.desktop" << EOF
[Desktop Entry]
Name=Input Remapper Autoload
Exec=input-remapper-control --autoload
Type=Application
NoDisplay=true
EOF

echo -e "${GREEN}${CHECK} Autostart entry for Input Remapper config autoload created at $HOME/.config/autostart/input-remapper.desktop${NC}"

###################################################
# Enable and start the service                   #
###################################################
echo -e "${YELLOW}${INFO} Enabling and starting the Input Remapper service...${NC}"
sleep 1
# Reload systemd manager configuration to recognize new/changed unit files
systemctl --user daemon-reload
sleep 1
# Enable the Input Remapper service to start on user login
systemctl --user enable input-remapper.service
# Start the Input Remapper service immediately
systemctl --user start input-remapper.service
sleep 1
# Check the status of the Input Remapper service
if systemctl --user is-active --quiet input-remapper.service; then
    echo -e "${GREEN}${CHECK} Input Remapper service started successfully.${NC}"
else
    echo -e "${RED}${ERROR} Failed to start Input Remapper service. Please check the service status with:${NC}"
    echo "  systemctl --user status input-remapper.service"
    exit 1
fi
echo -e "${GREEN}${CHECK} Done.${NC}"