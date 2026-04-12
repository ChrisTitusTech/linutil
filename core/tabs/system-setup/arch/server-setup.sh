#!/bin/bash

# Redirect stdout and stderr to archsetup.txt and still output to console
exec > >(tee -i archsetup.txt)
exec 2>&1

echo -ne "
-------------------------------------------------------------------------
 █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
-------------------------------------------------------------------------

Verifying Arch Linux ISO is Booted

"
if [ ! -f /usr/bin/pacstrap ]; then
    echo "This script must be run from an Arch Linux ISO environment."
    exit 1
fi

root_check() {
    if [[ "$(id -u)" != "0" ]]; then
        echo -ne "ERROR! This script must be run under the 'root' user!\n"
        exit 0
    fi
}

docker_check() {
    if awk -F/ '$2 == "docker"' /proc/self/cgroup | read -r; then
        echo -ne "ERROR! Docker container is not supported (at the moment)\n"
        exit 0
    elif [[ -f /.dockerenv ]]; then
        echo -ne "ERROR! Docker container is not supported (at the moment)\n"
        exit 0
    fi
}

arch_check() {
    if [[ ! -e /etc/arch-release ]]; then
        echo -ne "ERROR! This script must be run in Arch Linux!\n"
        exit 0
    fi
}

pacman_check() {
    if [[ -f /var/lib/pacman/db.lck ]]; then
        echo "ERROR! Pacman is blocked."
        echo -ne "If not running remove /var/lib/pacman/db.lck.\n"
        exit 0
    fi
}

background_checks() {
    root_check
    arch_check
    pacman_check
    docker_check
}

select_option() {
    local options=("$@")
    local num_options=${#options[@]}
    local selected=0
    local last_selected=-1

    while true; do
        # Move cursor up to the start of the menu
        if [ $last_selected -ne -1 ]; then
            echo -ne "\033[${num_options}A"
        fi

        if [ $last_selected -eq -1 ]; then
            echo "Please select an option using the arrow keys and Enter:"
        fi
        for i in "${!options[@]}"; do
            if [ "$i" -eq $selected ]; then
                echo "> ${options[$i]}"
            else
                echo "  ${options[$i]}"
            fi
        done

        last_selected=$selected

        # Read user input
        read -rsn1 key
        case $key in
            $'\x1b') # ESC sequence
                read -rsn2 -t 0.1 key
                case $key in
                    '[A') # Up arrow
                        ((selected--))
                        if [ $selected -lt 0 ]; then
                            selected=$((num_options - 1))
                        fi
                        ;;
                    '[B') # Down arrow
                        ((selected++))
                        if [ "$selected" -ge "$num_options" ]; then
                            selected=0
                        fi
                        ;;
                esac
                ;;
            '') # Enter key
                break
                ;;
        esac
    done

    return $selected
}

# @description Displays ArchTitus logo
# @noargs
logo () {
# This will be shown on every set as user is progressing
echo -ne "
-------------------------------------------------------------------------
 █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
------------------------------------------------------------------------
            Please select presetup settings for your system
------------------------------------------------------------------------
"
}
# @description This function will handle file systems. At this movement we are handling only
# btrfs and ext4. Others will be added in future.
filesystem () {
    echo -ne "
    Please Select your file system for both boot and root
    "
    options=("btrfs" "ext4" "luks" "exit")
    select_option "${options[@]}"

    case $? in
    0) export FS=btrfs;;
    1) export FS=ext4;;
    2)
        set_password "LUKS_PASSWORD"
        export FS=luks
        ;;
    3) exit ;;
    *) echo "Wrong option please select again"; filesystem;;
    esac
}

# @description Detects and sets timezone.
timezone () {
    time_zone="$(curl -sfm 5 https://ipapi.co/timezone)"
    while true; do
        read -r -p "Detected timezone: '$time_zone'. Press Enter to accept or type a new one: " input
        TIMEZONE="${input:-$time_zone}"
        if [[ -f "/usr/share/zoneinfo/${TIMEZONE}" ]]; then
            break
        else
            echo "ERROR! Timezone '${TIMEZONE}' not found. Please enter a valid timezone (e.g. America/New_York)."
        fi
    done
    export TIMEZONE
}
# @description Set user's keyboard mapping.
keymap () {
    echo -ne "
    Please select key board layout from this list"
    # These are default key maps as presented in official arch repo archinstall
    # shellcheck disable=SC1010
    options=(us by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru se sg si tr ua uk)

    select_option "${options[@]}"
    keymap=${options[$?]}

    if ! localectl list-x11-keymap-layouts 2>/dev/null | grep -qx "${keymap}"; then
        echo "WARNING: '${keymap}' was not found in X11 keymap layouts. It may still work for console keymaps."
    fi

    echo -ne "Your key boards layout: ${keymap} \n"
    export KEYMAP=$keymap
}

# @description Derives a default locale from the selected keymap and lets the user confirm or override.
set_locale () {
    declare -A keymap_locale_map=(
        [us]="en_US.UTF-8"  [uk]="en_GB.UTF-8"  [ca]="en_CA.UTF-8"
        [cf]="fr_CA.UTF-8"  [by]="be_BY.UTF-8"  [cz]="cs_CZ.UTF-8"
        [de]="de_DE.UTF-8"  [dk]="da_DK.UTF-8"  [es]="es_ES.UTF-8"
        [et]="et_EE.UTF-8"  [fa]="fa_IR.UTF-8"  [fi]="fi_FI.UTF-8"
        [fr]="fr_FR.UTF-8"  [gr]="el_GR.UTF-8"  [hu]="hu_HU.UTF-8"
        [il]="he_IL.UTF-8"  [it]="it_IT.UTF-8"  [lt]="lt_LT.UTF-8"
        [lv]="lv_LV.UTF-8"  [mk]="mk_MK.UTF-8"  [nl]="nl_NL.UTF-8"
        [no]="nb_NO.UTF-8"  [pl]="pl_PL.UTF-8"  [ro]="ro_RO.UTF-8"
        [ru]="ru_RU.UTF-8"  [se]="sv_SE.UTF-8"  [sg]="de_CH.UTF-8"
        [si]="sl_SI.UTF-8"  [tr]="tr_TR.UTF-8"  [ua]="uk_UA.UTF-8"
    )
    local suggested_locale="${keymap_locale_map[${KEYMAP}]:-en_US.UTF-8}"
    while true; do
        read -r -p "Detected locale: '$suggested_locale'. Press Enter to accept or type a new one (e.g. de_DE.UTF-8): " input
        LOCALE="${input:-$suggested_locale}"
        # Basic sanity check: must look like xx_XX.UTF-8 or similar
        if [[ "${LOCALE}" =~ ^[a-z]{2,3}_[A-Z]{2,3}\. ]]; then
            break
        else
            echo "ERROR! Locale '${LOCALE}' does not look valid. Please enter a locale like en_US.UTF-8."
        fi
    done
    export LOCALE
}

# @description Auto-detects drive type (SSD, MMC, or HDD) and sets mount options accordingly.
drivessd () {
    local disk_name
    disk_name=$(basename "${DISK}")

    if [[ "${DISK}" =~ "mmcblk" ]]; then
        export MOUNT_OPTIONS="noatime,compress=zstd:5,ssd,commit=120"
        echo "Detected MMC/eMMC drive (${disk_name}): using MMC mount options"
    elif [[ -f "/sys/block/${disk_name}/queue/rotational" ]]; then
        local rotational
        rotational=$(cat "/sys/block/${disk_name}/queue/rotational")
        if [[ "${rotational}" == "0" ]]; then
            export MOUNT_OPTIONS="noatime,compress=zstd,ssd,commit=120"
            echo "Detected SSD/NVMe drive (${disk_name}): using SSD mount options"
        else
            export MOUNT_OPTIONS="noatime,compress=zstd,commit=120"
            echo "Detected HDD (${disk_name}): using HDD mount options"
        fi
    else
        export MOUNT_OPTIONS="noatime,compress=zstd,ssd,commit=120"
        echo "Could not detect drive type for ${disk_name}, defaulting to SSD mount options"
    fi
}

# @description Disk selection for drive to be used with installation.
diskpart () {
echo -ne "
------------------------------------------------------------------------
    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK
    Please make sure you know what you are doing because
    after formatting your disk there is no way to get data back
    *****BACKUP YOUR DATA BEFORE CONTINUING*****
    ***I AM NOT RESPONSIBLE FOR ANY DATA LOSS***
------------------------------------------------------------------------

"

    #Loop through selection if non-viable device (mmcblkXbootY, mmcblkXrpbm, etc) is selected
	   while true
	   do
       PS3='
       Select the disk to install on: '
       mapfile -t options < <(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}')

       select_option "${options[@]}"
       disk=${options[$?]%|*}
       if [[ ! "${disk%|*}" =~  ^/dev/mmcblk[0-9]+[a-z]+[0-9]? ]]
    	  then
    		    break
    	  fi
    	  echo -e "\n${disk%|*} is not a viable install drive \n"
    done

    echo -e "\n${disk%|*} selected \n"
        export DISK=${disk%|*}

    drivessd
}

# @description Gather username and password to be used for installation.
userinfo () {
    # Loop through user input until the user gives a valid username
    while true
    do
            read -r -p "Please enter username: " username
            if [[ "${username,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]
            then
                    break
            fi
            echo "Incorrect username."
    done
    export USERNAME=$username

    while true
    do
        read -rs -p "Please enter password: " PASSWORD1
        echo -ne "\n"
        read -rs -p "Please re-enter password: " PASSWORD2
        echo -ne "\n"
        if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
            break
        else
            echo -ne "ERROR! Passwords do not match. \n"
        fi
    done
    export PASSWORD=$PASSWORD1

     # Loop through user input until the user gives a valid hostname, but allow the user to force save
    while true
    do
            read -r -p "Please name your machine: " name_of_machine
            # hostname regex (!!couldn't find spec for computer name!!)
            if [[ "${name_of_machine,,}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]
            then
                    break
            fi
            # if validation fails allow the user to force saving of the hostname
            read -r -p "Hostname doesn't seem correct. Do you still want to save it? (y/n)" force
            if [[ "${force,,}" = "y" ]]
            then
                    break
            fi
    done
    export NAME_OF_MACHINE=$name_of_machine
}

# Starting functions
background_checks
clear
logo
userinfo
clear
logo
diskpart
clear
logo
filesystem
clear
logo
timezone
clear
logo
keymap
clear
logo
set_locale

echo "Setting up mirrors for optimal download"
iso=$(curl -4 ifconfig.io/country_code)
timedatectl set-ntp true
pacman -Sy
pacman -S --noconfirm archlinux-keyring #update keyrings to latest to prevent packages failing to install
pacman -S --noconfirm --needed pacman-contrib terminus-font
setfont ter-v18b
pacman -S --noconfirm --needed rate-mirrors rsync grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -ne "
-------------------------------------------------------------------------
                    Setting up $iso mirrors for faster downloads
-------------------------------------------------------------------------
"
if rate-mirrors --allow-root --entry-country="$iso" --max-jumps=0 --save=/etc/pacman.d/mirrorlist arch --max-delay=21600; then
    if [[ $(grep -c "Server =" /etc/pacman.d/mirrorlist) -lt 5 ]]; then
        echo "rate-mirrors returned fewer than 5 mirrors, restoring backup"
        cp /etc/pacman.d/mirrorlist.backup /etc/pacman.d/mirrorlist
    fi
else
    echo "rate-mirrors failed, restoring backup mirrorlist"
    cp /etc/pacman.d/mirrorlist.backup /etc/pacman.d/mirrorlist
fi

if [ ! -d "/mnt" ]; then
    mkdir /mnt
fi
echo -ne "
-------------------------------------------------------------------------
                    Installing Prerequisites
-------------------------------------------------------------------------
"
pacman -S --noconfirm --needed gptfdisk btrfs-progs glibc
echo -ne "
-------------------------------------------------------------------------
                    Formatting Disk
-------------------------------------------------------------------------
"
umount -A --recursive /mnt # make sure everything is unmounted before we start
# disk prep
sgdisk -Z "${DISK}" # zap all on disk
sgdisk -a 2048 -o "${DISK}" # new gpt disk 2048 alignment

# create partitions
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' "${DISK}" # partition 1 (BIOS Boot Partition)
sgdisk -n 2::+1GiB --typecode=2:ef00 --change-name=2:'EFIBOOT' "${DISK}" # partition 2 (UEFI Boot Partition)
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' "${DISK}" # partition 3 (Root), default start, remaining
if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
    sgdisk -A 1:set:2 "${DISK}"
fi
partprobe "${DISK}" # reread partition table to ensure it is correct

# make filesystems
echo -ne "
-------------------------------------------------------------------------
                    Creating Filesystems
-------------------------------------------------------------------------
"
# @description Creates the btrfs subvolumes.
createsubvolumes () {
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    # Set @ as the default subvolume so genfstab records subvolid=256 (not 5)
    # Path form requires btrfs-progs >= 5.6 (standard on Arch rolling)
    btrfs subvolume set-default /mnt/@
}

# @description Mount all btrfs subvolumes after root has been mounted.
mountallsubvol () {
    mount -o "${MOUNT_OPTIONS}",subvol=@home "${BTRFS_DEVICE}" /mnt/home
}

# @description BTRFS subvolulme creation and mounting.
subvolumesetup () {
# create nonroot subvolumes
    createsubvolumes
# unmount root to remount with subvolume
    umount /mnt
# mount @ subvolume
    mount -o "${MOUNT_OPTIONS}",subvol=@ "${BTRFS_DEVICE}" /mnt
# make directories for subvolumes
    mkdir -p /mnt/home
# mount subvolumes
    mountallsubvol
}

if [[ "${DISK}" =~ "nvme"|"mmcblk" ]]; then
    partition2=${DISK}p2
    partition3=${DISK}p3
else
    partition2=${DISK}2
    partition3=${DISK}3
fi

if [[ "${FS}" == "btrfs" ]]; then
    mkfs.fat -F32 -n "EFIBOOT" "${partition2}"
    mkfs.btrfs -f "${partition3}"
    mount -t btrfs "${partition3}" /mnt
    BTRFS_DEVICE="${partition3}"
    subvolumesetup
elif [[ "${FS}" == "ext4" ]]; then
    mkfs.fat -F32 -n "EFIBOOT" "${partition2}"
    mkfs.ext4 "${partition3}"
    mount -t ext4 "${partition3}" /mnt
elif [[ "${FS}" == "luks" ]]; then
    mkfs.fat -F32 "${partition2}"
# enter luks password to cryptsetup and format root partition
    echo -n "${LUKS_PASSWORD}" | cryptsetup -y -v luksFormat "${partition3}" -
# open luks container and ROOT will be place holder
    echo -n "${LUKS_PASSWORD}" | cryptsetup open "${partition3}" ROOT -
# now format that container
    mkfs.btrfs /dev/mapper/ROOT
# create subvolumes for btrfs
    mount -t btrfs /dev/mapper/ROOT /mnt
    BTRFS_DEVICE=/dev/mapper/ROOT
    subvolumesetup
    ENCRYPTED_PARTITION_UUID=$(blkid -s UUID -o value "${partition3}")
fi

BOOT_UUID=$(blkid -s UUID -o value "${partition2}")

sync
if ! mountpoint -q /mnt; then
    echo "ERROR! Failed to mount ${partition3} to /mnt after multiple attempts."
    exit 1
fi
mkdir -p /mnt/boot
mount -U "${BOOT_UUID}" /mnt/boot/

if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted can not continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi

echo -ne "
-------------------------------------------------------------------------
                    Arch Install on Main Drive
-------------------------------------------------------------------------
"
# Pre-seed machine-id so systemd's post-install hook skips entropy-blocking generation
mkdir -p /mnt/etc
systemd-machine-id-setup --print > /mnt/etc/machine-id

if [[ ! -d "/sys/firmware/efi" ]]; then
    pacstrap /mnt base base-devel linux-lts linux-firmware --noconfirm --needed
else
    pacstrap /mnt base base-devel linux-lts linux-firmware efibootmgr --noconfirm --needed
fi
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

genfstab -U /mnt >> /mnt/etc/fstab
echo "
  Generated /etc/fstab:
"
cat /mnt/etc/fstab
echo -ne "
-------------------------------------------------------------------------
                    GRUB BIOS Bootloader Install & Check
-------------------------------------------------------------------------
"
if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/mnt/boot "${DISK}"
fi
echo -ne "
-------------------------------------------------------------------------
                    Checking for low memory systems <8G
-------------------------------------------------------------------------
"
TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTAL_MEM -lt 8000000 ]]; then
    # Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
    mkdir -p /mnt/opt/swap # make a dir that we can apply NOCOW to to make it btrfs-friendly.
    if findmnt -n -o FSTYPE /mnt | grep -q btrfs; then
        chattr +C /mnt/opt/swap # apply NOCOW, btrfs needs that.
    fi
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile # set permissions.
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    # The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the system itself.
    echo "/opt/swap/swapfile    none    swap    sw    0    0" >> /mnt/etc/fstab # Add swap to fstab, so it KEEPS working after installation.
fi

gpu_type=$(lspci | grep -E "VGA|3D|Display")

arch-chroot /mnt /bin/bash -c "KEYMAP='${KEYMAP}' /bin/bash" <<EOF

echo -ne "
-------------------------------------------------------------------------
                    Network Setup
-------------------------------------------------------------------------
"
pacman -S --noconfirm --needed networkmanager
systemctl enable NetworkManager
echo -ne "
-------------------------------------------------------------------------
                    Setting up mirrors for optimal download
-------------------------------------------------------------------------
"
pacman -S --noconfirm --needed pacman-contrib curl terminus-font
pacman -S --noconfirm --needed rsync grub arch-install-scripts git ntp wget
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

NUM_CORES=$(nproc)
sed -i "s/#MAKEFLAGS=\"-j\"/MAKEFLAGS=\"-j$NUM_CORES\"/g" /etc/makepkg.conf
sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $NUM_CORES -z -)/g" /etc/makepkg.conf
echo -ne "
-------------------------------------------------------------------------
                    Setup Language to US and set locale
-------------------------------------------------------------------------
"
sed -i "s/^#${LOCALE}/${LOCALE}/" /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone ${TIMEZONE}
timedatectl --no-ask-password set-ntp true
localectl --no-ask-password set-locale LANG="${LOCALE}" LC_TIME="${LOCALE}"
ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

# Set keymaps
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf
echo "XKBLAYOUT=${KEYMAP}" >> /etc/vconsole.conf
echo "Keymap set to: ${KEYMAP}"

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

#Set colors and enable the easter egg
sed -i 's/^#Color/Color\nILoveCandy/' /etc/pacman.conf

#Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm --needed

echo -ne "
-------------------------------------------------------------------------
                    Installing Microcode
-------------------------------------------------------------------------
"
# determine processor type and install microcode
if grep -q "GenuineIntel" /proc/cpuinfo; then
    echo "Installing Intel microcode"
    pacman -S --noconfirm --needed intel-ucode
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    echo "Installing AMD microcode"
    pacman -S --noconfirm --needed amd-ucode
else
    echo "Unable to determine CPU vendor. Skipping microcode installation."
fi

echo -ne "
-------------------------------------------------------------------------
                    Installing Graphics Drivers
-------------------------------------------------------------------------
"
# Graphics Drivers find and install
if echo "${gpu_type}" | grep -E "NVIDIA|GeForce"; then
    echo "Installing NVIDIA drivers: nvidia-lts"
    pacman -S --noconfirm --needed nvidia-lts
elif echo "${gpu_type}" | grep 'VGA' | grep -E "Radeon|AMD"; then
    echo "Installing AMD drivers: xf86-video-amdgpu"
    pacman -S --noconfirm --needed xf86-video-amdgpu
elif echo "${gpu_type}" | grep -E "Integrated Graphics Controller"; then
    echo "Installing Intel drivers:"
    pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
elif echo "${gpu_type}" | grep -E "Intel Corporation UHD"; then
    echo "Installing Intel UHD drivers:"
    pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
fi

echo -ne "
-------------------------------------------------------------------------
                    Adding User
-------------------------------------------------------------------------
"
groupadd libvirt
useradd -m -G wheel,libvirt -s /bin/bash $USERNAME
echo "$USERNAME created, home directory created, added to wheel and libvirt group, default shell set to /bin/bash"
echo "$USERNAME:$PASSWORD" | chpasswd
echo "$USERNAME password set"
echo $NAME_OF_MACHINE > /etc/hostname

if [[ ${FS} == "luks" ]]; then
# Making sure to edit mkinitcpio conf if luks is selected
# add encrypt in mkinitcpio.conf before filesystems in hooks
    sed -i 's/filesystems/encrypt filesystems/g' /etc/mkinitcpio.conf
# making mkinitcpio with linux kernel
    mkinitcpio -p linux-lts
fi

echo -ne "
-------------------------------------------------------------------------
 █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
-------------------------------------------------------------------------

Final Setup and Configurations
GRUB EFI Bootloader Install & Check
"

if [[ -d "/sys/firmware/efi" ]]; then
    grub-install --efi-directory=/boot ${DISK}
fi

echo -ne "
-------------------------------------------------------------------------
               Creating Grub Boot Menu
-------------------------------------------------------------------------
"
# set kernel parameter for decrypting the drive
if [[ "${FS}" == "luks" ]]; then
sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:ROOT root=/dev/mapper/ROOT %g" /etc/default/grub
fi
# set kernel parameter for adding splash screen
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& splash /' /etc/default/grub

echo -e "Updating grub..."
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "All set!"

echo -ne "
-------------------------------------------------------------------------
                    Enabling Essential Services
-------------------------------------------------------------------------
"
ntpd -qg
systemctl enable ntpd.service
echo "  NTP enabled"
systemctl disable dhcpcd.service
echo "  DHCP disabled"
systemctl enable NetworkManager.service
echo "  NetworkManager enabled"

echo -ne "
-------------------------------------------------------------------------
                    Cleaning
-------------------------------------------------------------------------
"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
EOF
