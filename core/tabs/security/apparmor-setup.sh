#! /bin/bash
# AppArmor Setup Script
# This script installs and configures AppArmor on supported Linux distributions.
Enable AppArmor support using AppArmor.d profiles (Optional)
Add the following kernel parameters to your Boot Manager, see Boot Manager Configuration for reference

lsm=landlock,lockdown,yama,integrity,apparmor,bpf

Install apparmor and apparmord (Set of over +1500 profiles) packages

Terminal window
sudo pacman -S apparmor apparmor.d-git

Enable/Start AppArmor service

Terminal window
systemctl enable --now apparmor.service

Enable caching for AppArmor profiles

/etc/apparmor/parser.conf
## Add the following lines:
write-cache
Optimize=compress-fast

Save the file and reboot.