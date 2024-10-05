#!/bin/sh -e

. ../../common-script.sh

# This script automates the installation and root snapshot configuration of Snapper and installs Grub-Btrfs on Fedora. Also installs python3-dnf-plugin-snapper package for automatic snapshots after dnf commands.

# Check the root filesystem type
checkFs() {
    fs_type=$(findmnt -n -o FSTYPE /)
    if [ "$fs_type" != "btrfs" ]; then
      printf "%b\n" "${RED}This operation can only be performed on a Btrfs filesystem.${RC}"
      exit 1
    fi
    printf "%b\n" "${GREEN}Btrfs filesystem detected. Continuing with the operation...${RC}"
}

# Install Btrfs-Assistant/snapper and dependencies
installBtrfsStack() {
    if ! command_exists btrfs-assistant; then
    printf "%b\n" "${YELLOW}Installing Btrfs Assistant with snapper...${RC}"
    case "$PACKAGER" in
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y btrfs-assistant
            ;;
            *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
    else
        printf "%b\n" "${GREEN}Btrfs Assistant is already installed.${RC}"
    fi
}

# Create first snapper config for root and home and create new manual snapshots
configureSnapper() {
    if command_exists snapper; then
        printf "%b\n" "${YELLOW}Snapper tool detected. Do you want to configure root and home configs and take first snapshots? (y/n): ${RC}"
        read -r response
        case "$response" in
            [yY]*)
                ;;
            *)
                printf "%b\n" "${GREEN}Snapper configurations will not be changed.${RC}"
                return
                ;;
        esac
    else
        "$ESCALATION_TOOL" "$PACKAGER" install -y snapper python3-dnf-plugin-snapper
    fi
    printf "%b\n" "${YELLOW}Creating snapper root(/) and home config and taking the first snapshots...${RC}"
    snapper -c root create-config / && snapper -c root create --description "First root Snapshot"
    snapper -c home create-config /home && snapper -c home create --description "First home Snapshot"
    printf "%b\n" "${YELLOW}Updating timeline settings...${RC}"
    # Modifyling default timeline root config
    "$ESCALATION_TOOL" sed -i '
        s/^TIMELINE_LIMIT_HOURLY="[^"]*"/TIMELINE_LIMIT_HOURLY="1"/;
        s/^TIMELINE_LIMIT_DAILY="[^"]*"/TIMELINE_LIMIT_DAILY="2"/;
        s/^TIMELINE_LIMIT_WEEKLY="[^"]*"/TIMELINE_LIMIT_WEEKLY="1"/;
        s/^TIMELINE_LIMIT_MONTHLY="[^"]*"/TIMELINE_LIMIT_MONTHLY="0"/;
        s/^TIMELINE_LIMIT_YEARLY="[^"]*"/TIMELINE_LIMIT_YEARLY="0"/
    ' /etc/snapper/configs/root
    # Modifyling default timeline for home config
    "$ESCALATION_TOOL" sed -i '
        s/^TIMELINE_LIMIT_HOURLY="[^"]*"/TIMELINE_LIMIT_HOURLY="2"/;
        s/^TIMELINE_LIMIT_DAILY="[^"]*"/TIMELINE_LIMIT_DAILY="1"/;
        s/^TIMELINE_LIMIT_WEEKLY="[^"]*"/TIMELINE_LIMIT_WEEKLY="0"/;
        s/^TIMELINE_LIMIT_MONTHLY="[^"]*"/TIMELINE_LIMIT_MONTHLY="1"/;
        s/^TIMELINE_LIMIT_YEARLY="[^"]*"/TIMELINE_LIMIT_YEARLY="0"/
    ' /etc/snapper/configs/home
    printf "%b\n" "${GREEN}Snapper configs and first snapshots created.${RC}"
    serviceStartEnable
}

# Starting services
serviceStartEnable() {
    printf "%b\n" "${YELLOW}Starting and enabling snapper-timeline.timer and snapper-cleanup.timer services...${RC}"
    systemctl start snapper-timeline.timer && systemctl enable snapper-timeline.timer #enables scheduled timeline snapshots
    systemctl start snapper-cleanup.timer && systemctl enable snapper-cleanup.timer #enables scheduled snapshot cleanup
    printf "%b\n" "${GREEN}Snapper services started and enabled.${RC}"
}

# Ask user if they want to install grub-btrfs
askInstallGrubBtrfs() {
    printf "%b\n" "${YELLOW}You can skip installing grub-btrfs and use only Btrfs Assistant GUI or snapper CLI.${RC}"
    printf "%b\n" "${RED}grub-btrfs may cause problems on encrypted systems with secure boot/tpm. ${RC}"
    printf "%b\n" "${YELLOW}Do you want to install grub-btrfs? (y/n): ${RC}"
    read -r response
    case "$response" in
        [yY]*)
            installGrubBtrfs
            ;;
        *)
            printf "%b\n" "${GREEN}Skipping grub-btrfs installation.${RC}"
            ;;
    esac
}

# Install grub-btrfs
installGrubBtrfs() {
    # Check if the grub-btrfs dir exists before attempting to clone into it.
    printf "%b\n" "${YELLOW}Downloading grub-btrfs and installing dependencies...${RC}"
    if [ -d "$HOME/grub-btrfs" ]; then
        rm -rf "$HOME/grub-btrfs"
    fi
    "$ESCALATION_TOOL" "$PACKAGER" install -y make git inotify-tools
    cd "$HOME" && git clone https://github.com/Antynea/grub-btrfs
    printf "%b\n" "${YELLOW}Installing grub-btrfs...${RC}"
    cd "$HOME/grub-btrfs"
    printf "%b\n" "${YELLOW}Modifying grub-btrfs configuration for Fedora...${RC}"
    sed -i '/#GRUB_BTRFS_SNAPSHOT_KERNEL/a GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="systemd.volatile=state"' config
    sed -i '/#GRUB_BTRFS_GRUB_DIRNAME/a GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"' config
    sed -i '/#GRUB_BTRFS_MKCONFIG=/a GRUB_BTRFS_MKCONFIG=/sbin/grub2-mkconfig' config
    sed -i '/#GRUB_BTRFS_SCRIPT_CHECK=/a GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check' config
    "$ESCALATION_TOOL" make install
    # Update grub.cfg and enable grub-btrfsd service
    printf "%b\n" "${YELLOW}Updating grub configuration and enabling grub-btrfsd service...${RC}"
    "$ESCALATION_TOOL" grub2-mkconfig -o /boot/grub2/grub.cfg && systemctl enable --now grub-btrfsd.service
    printf "%b\n" "${YELLOW}Cleaning up installation files...${RC}"
    cd .. && rm -rf "$HOME/grub-btrfs" #deletes downloaded git folder
    printf "%b\n" "${GREEN}Grub-btrfs installed and service enabled.${RC}"
    printf "%b\n" "${CYAN}Notice: To perform a system recovery via grub-btrfs, after booting into your snapshot, do the 'restore' operation via Btrfs Assistant GUI.${RC}"
}

# Post install information
someNotices() {
    printf "%b\n" "${GREEN}Notice: Setup process completed.${RC}"
    printf "%b\n" "${YELLOW}Notice: You can manage snapshots from GUI with Btrfs Assistant or CLI with snapper.${RC}"
    printf "%b\n" "${YELLOW}Notice: You may change (Hourly, daily, weekly, monthly, yearly) timeline settings with Btrfs Assistant GUI.${RC}"
    printf "%b\n" "${CYAN}Notice: If you used the default Fedora disk partitioning during OS installation, the /boot configured as an separate EXT4 partition. Therefore, it cannot be included in root snapshots. Backup separately...${RC}"
}

checkEnv
checkEscalationTool
checkFs
installBtrfsStack
configureSnapper
askInstallGrubBtrfs
someNotices
