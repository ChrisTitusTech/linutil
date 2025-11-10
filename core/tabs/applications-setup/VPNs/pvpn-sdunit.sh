#!/bin/bash
# Creates a systemd service for ProtonVPN unit and service, enables and starts it
# Usage: bash postinstall.sh
# Work in progress
# Source pretty output definitions
source ./pretty-output.sh

echo "Starting ProtonVPN systemd service setup..."
echo "creating the directory for the service file..."
mkdir -p ~/.config/systemd/user
echo "Directory created."

###################################################
# Creating the service file                       #
###################################################

echo "Creating the service file..."
cat > "$SERVICE_FILE" << EOF
[Unit]
After=graphical.target network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/protonvpn-cli connect --fastest
Restart=on-failure

[Install]
WantedBy=default.target
EOF

echo "Done. Service file created at $SERVICE_FILE"

sleep 1

# Enable and start the service                 #
echo "Enabling and starting the service..."
systemctl --user enable protonvpn.service
sleep 2
systemctl --user start protonvpn.service
echo "Waiting 5 seconds for the service to start..."
sleep 5

################################################
# Check status of the service                  #
################################################

echo "Checking service status..."
if systemctl --user is-active --quiet protonvpn.service; then
    echo "Service started successfully."
else
    echo "Warning: Service may not have started. Check logs."
fi
echo "Done. You can check the status with: systemctl --user status protonvpn.service"
echo "To view logs: journalctl --user -u protonvpn.service"