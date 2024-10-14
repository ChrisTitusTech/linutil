#!/bin/sh -e

. ../common-script.sh

# setleds can be used in all distros
# This method works by calling a script using systemd service

# Create a script to toggle numlock

create_file() {
  printf "%b\n" "Creating script..."
  elevated_execution tee "/usr/local/bin/numlock" >/dev/null <<'EOF'
#!/bin/bash

for tty in /dev/tty{1..6}
do
    /usr/bin/setleds -D +num < "$tty"; 
done
EOF

  elevated_execution chmod +x /usr/local/bin/numlock
}

# Create a systemd service to run the script on boot
create_service() {
  printf "%b\n" "Creating service..."
  elevated_execution tee "/etc/systemd/system/numlock.service" >/dev/null <<'EOF'
[Unit]
Description=numlock
        
[Service]
ExecStart=/usr/local/bin/numlock
StandardInput=tty
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
}

numlockSetup() {
  # Check if the script and service files exists
  if [ ! -f "/usr/local/bin/numlock" ]; then
    create_file
  fi

  if [ ! -f "/etc/systemd/system/numlock.service" ]; then
    create_service
  fi

  printf "%b" "Do you want to enable Numlock on boot? (y/N): "
  read -r confirm
  if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    elevated_execution systemctl enable numlock.service --quiet
    printf "%b\n" "Numlock will be enabled on boot"
  else
    elevated_execution systemctl disable numlock.service --quiet
    printf "%b\n" "Numlock will not be enabled on boot"
  fi
}

checkEnv
checkEscalationTool
numlockSetup
