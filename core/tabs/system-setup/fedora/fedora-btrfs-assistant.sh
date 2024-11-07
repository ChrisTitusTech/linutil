#!/bin/sh -e

. ../../common-script.sh

# This script automates the installation and root and home snapshot configuration of Snapper and installs Grub-Btrfs on Fedora.
# Also installs python3-dnf-plugin-snapper package for automatic snapshots after dnf commands.

# Install Btrfs-Assistant/snapper and dependencies
installBtrfsStack() {
    if ! command_exists btrfs-assistant; then
        printf "%b\n" "${YELLOW}==========================================${RC}"
        printf "%b\n" "${YELLOW}Installing Btrfs Assistant with snapper...${RC}"
        printf "%b\n" "${YELLOW}==========================================${RC}"
        case "$PACKAGER" in
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y btrfs-assistant python3-dnf-plugin-snapper
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
    printf "%b\n" "${YELLOW}===========================================================================${RC}"
    printf "%b\n" "${YELLOW}Creating snapper root(/) and /home config and taking the first snapshots...${RC}"
    printf "%b\n" "${YELLOW}===========================================================================${RC}"
    "$ESCALATION_TOOL" snapper -c home create-config /home && "$ESCALATION_TOOL" snapper -c home create --description "First home Snapshot"
    "$ESCALATION_TOOL" snapper -c root create-config / && "$ESCALATION_TOOL" snapper -c root create --description "First root Snapshot"
    printf "%b\n" "${YELLOW}Updating timeline settings...${RC}"
    # Modifyling default timeline root config
    "$ESCALATION_TOOL" sed -i'' '
        s/^TIMELINE_LIMIT_HOURLY="[^"]*"/TIMELINE_LIMIT_HOURLY="1"/;
        s/^TIMELINE_LIMIT_DAILY="[^"]*"/TIMELINE_LIMIT_DAILY="2"/;
        s/^TIMELINE_LIMIT_WEEKLY="[^"]*"/TIMELINE_LIMIT_WEEKLY="1"/;
        s/^TIMELINE_LIMIT_MONTHLY="[^"]*"/TIMELINE_LIMIT_MONTHLY="0"/;
        s/^TIMELINE_LIMIT_YEARLY="[^"]*"/TIMELINE_LIMIT_YEARLY="0"/
    ' /etc/snapper/configs/root
    # Modifyling default timeline for home config
    "$ESCALATION_TOOL" sed -i'' '
        s/^TIMELINE_LIMIT_HOURLY="[^"]*"/TIMELINE_LIMIT_HOURLY="2"/;
        s/^TIMELINE_LIMIT_DAILY="[^"]*"/TIMELINE_LIMIT_DAILY="1"/;
        s/^TIMELINE_LIMIT_WEEKLY="[^"]*"/TIMELINE_LIMIT_WEEKLY="0"/;
        s/^TIMELINE_LIMIT_MONTHLY="[^"]*"/TIMELINE_LIMIT_MONTHLY="1"/;
        s/^TIMELINE_LIMIT_YEARLY="[^"]*"/TIMELINE_LIMIT_YEARLY="0"/
    ' /etc/snapper/configs/home
    printf "%b\n" "${GREEN}Snapper configs and first snapshots created.${RC}"
}

# Starting services
serviceStartEnable() {
    printf "%b\n" "${YELLOW}==================================================================================${RC}"
    printf "%b\n" "${YELLOW}Starting and enabling snapper-timeline.timer and snapper-cleanup.timer services...${RC}"
    printf "%b\n" "${YELLOW}==================================================================================${RC}"
    "$ESCALATION_TOOL" systemctl enable --now snapper-timeline.timer
    "$ESCALATION_TOOL" systemctl enable --now snapper-cleanup.timer
    printf "%b\n" "${GREEN}Snapper services started and enabled.${RC}"
}

# Ask user if they want to install grub-btrfs
askInstallGrubBtrfs() {
    printf "%b\n" "${YELLOW}=====================================${RC}"
    printf "%b\n" "${YELLOW}(optional) grub-btrfs installation...${RC}"
    printf "%b\n" "${YELLOW}=====================================${RC}"
    printf "%b\n" "${YELLOW}You can skip installing grub-btrfs and use only Btrfs Assistant GUI or snapper CLI.${RC}"
    printf "%b\n" "${CYAN}Notice: grub-btrfs may cause problems with booting into snapshots and other OSes on systems with secure boot/tpm. You will be asked to apply mitigation for this issue in next step.${RC}"

    while true; do
        printf "%b" "${YELLOW}Do you want to install grub-btrfs? Press (y) for yes, (n) for no, (f) to apply tpm mitigation to already installed grub-btrfs: ${RC}"
        read -r response
        case "$response" in
            [yY]*)
                installGrubBtrfs
                break
                ;;
            [nN]*)
                printf "%b\n" "${GREEN}Skipping grub-btrfs installation.${RC}"
                break
                ;;
            [fF]*)
                mitigateTpmError
                break
                ;;
            *)
                printf "%b\n" "${RED}Invalid input. Please enter 'y' for yes, 'n' for no, or (f) to apply tpm mitigation to already installed grub-btrfs.${RC}"
                ;;
        esac
    done
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
    sed -i'' '/#GRUB_BTRFS_SNAPSHOT_KERNEL/a GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="systemd.volatile=state"' config
    sed -i'' '/#GRUB_BTRFS_GRUB_DIRNAME/a GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"' config
    sed -i'' '/#GRUB_BTRFS_MKCONFIG=/a GRUB_BTRFS_MKCONFIG=/sbin/grub2-mkconfig' config
    sed -i'' '/#GRUB_BTRFS_SCRIPT_CHECK=/a GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check' config
    "$ESCALATION_TOOL" make install
    printf "%b\n" "${YELLOW}Updating grub configuration and enabling grub-btrfsd service...${RC}"
    "$ESCALATION_TOOL" grub2-mkconfig -o /boot/grub2/grub.cfg && "$ESCALATION_TOOL" systemctl enable --now grub-btrfsd.service
    printf "%b\n" "${YELLOW}Cleaning up installation files...${RC}"
    cd .. && rm -rf "$HOME/grub-btrfs"
    printf "%b\n" "${GREEN}Grub-btrfs installed and service enabled.${RC}"
    printf "%b\n" "${CYAN}Notice: To perform a system recovery via grub-btrfs, perform a restore operation with Btrfs Assistant GUI after booting into the snapshot.${RC}"
    mitigateTpmError
}

mitigateTpmError() {
    printf "%b\n" "${YELLOW}===============================================${RC}"
    printf "%b\n" "${YELLOW}Mitigation for 'tpm.c:150:unknown TPM error'...${RC}"
    printf "%b\n" "${YELLOW}===============================================${RC}"
    printf "%b\n" "${YELLOW}Some systems with secure boot/tpm may encounter 'tpm.c:150:unknown TPM error' when booting into snapshots.${RC}"
    printf "%b\n" "${YELLOW}If you encounter this issue, you can come back later and apply this mitigation or you can apply it now.${RC}"
    while true; do
        printf "%b\n" "${YELLOW}Do you want to apply the TPM error mitigation? (y/n): ${RC}"
        read -r response
        case "$response" in
            [yY]*)
                printf "%b\n" "${YELLOW}Creating /etc/grub.d/02_tpm file...${RC}"
                echo '#!/bin/sh' | "$ESCALATION_TOOL" tee /etc/grub.d/02_tpm > /dev/null
                echo 'echo "rmmod tpm"' | "$ESCALATION_TOOL" tee -a /etc/grub.d/02_tpm > /dev/null
                "$ESCALATION_TOOL" chmod +x /etc/grub.d/02_tpm # makes the file executable
                "$ESCALATION_TOOL" grub2-mkconfig -o /boot/grub2/grub.cfg # updates grub config
                printf "%b\n" "${GREEN}Mitigation applied and grub config updated.${RC}"
                break
                ;;
            [nN]*)
                printf "%b\n" "${GREEN}Skipping TPM error mitigation.${RC}"
                break
                ;;
            *)
                printf "%b\n" "${RED}Invalid input. Please enter 'y' for yes or 'n' for no.${RC}"
                ;;
        esac
    done
}

# Post install information
someNotices() {
    printf "%b\n" "${YELLOW}================================NOTICES================================${RC}"
    printf "%b\n" "${YELLOW}Notice: You can manage snapshots from GUI with Btrfs Assistant or CLI with snapper.${RC}"
    printf "%b\n" "${YELLOW}Notice: You may change (Hourly, daily, weekly, monthly, yearly) timeline settings with Btrfs Assistant GUI.${RC}"
    printf "%b\n" "${RED}Notice: If you used the default Fedora disk partitioning during OS installation, the /boot configured as an separate EXT4 partition. Therefore, it cannot be included in root snapshots. Backup separately...${RC}"
    printf "%b\n" "${YELLOW}================================NOTICES================================${RC}"
    printf "%b\n" "${GREEN}Setup process completed.${RC}"
}

checkEnv
checkEscalationTool
installBtrfsStack
configureSnapper
serviceStartEnable
askInstallGrubBtrfs
someNotices
