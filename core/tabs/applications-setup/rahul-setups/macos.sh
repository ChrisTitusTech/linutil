#!/usr/bin/env bash


. ../../common-script.sh  # Ensure this file exists and is correctly sourced

setup_macos() {
    # Step 1: Install required packages
    echo "Installing required packages..."
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm qemu virt-manager git wget \
                libguestfs p7zip base-devel dmg2img tesseract tesseract-data-eng genisoimage vim net-tools screen
            ;;
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y qemu-system uml-utilities virt-manager git wget \
                libguestfs-tools p7zip-full make dmg2img tesseract-ocr \
                tesseract-ocr-eng genisoimage vim net-tools screen
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y qemu-system-x86 virt-manager git wget \
                libguestfs-tools-c p7zip make dmg2img tesseract tesseract-langpack-eng genisoimage vim net-tools screen
            ;;
        *)
            echo "Unsupported package manager: $PACKAGER"
            exit 1
            ;;
    esac

    # Step 2: Clone the MAC-KVM repository
    echo "Cloning the MAC-KVM repository..."
    if [ ! -d "/home/$(logname)/github/MAC-KVM" ]; then
        cd /home/$(logname)
        if [ ! -d "github" ]; then
            mkdir github
        fi
        cd github
        git clone --depth 1 --recursive https://github.com/rahuljangirwork/MAC-KVM.git
    else
        echo "MAC-KVM repository already exists. Skipping cloning."
    fi
    cd /home/$(logname)/github/MAC-KVM

    # Step 3: Configure KVM parameters
    echo "Configuring KVM..."
    if [ "$(cat /sys/module/kvm/parameters/ignore_msrs)" != "1" ]; then
        sudo modprobe kvm
        echo 1 | sudo tee /sys/module/kvm/parameters/ignore_msrs > /dev/null
    else
        echo "KVM parameters already configured."
    fi

    # Make the change permanent
    if grep -iq intel /proc/cpuinfo; then
        echo "Detected Intel CPU. Applying Intel-specific KVM configuration."
        [ ! -f /etc/modprobe.d/kvm.conf ] && sudo cp kvm.conf /etc/modprobe.d/kvm.conf
    else
        echo "Detected AMD CPU. Applying AMD-specific KVM configuration."
        [ ! -f /etc/modprobe.d/kvm.conf ] && sudo cp kvm_amd.conf /etc/modprobe.d/kvm.conf
    fi

    # Step 4: Add user to kvm and libvirt groups
    echo "Adding the user $(logname) to kvm and libvirt groups..."
    if ! groups $(logname) | grep -q '\bkvm\b'; then
        sudo /usr/sbin/usermod -aG kvm $(logname)
    else
        echo "$(logname) is already in kvm group."
    fi
    if ! groups $(logname) | grep -q '\blibvirt\b'; then
        sudo /usr/sbin/usermod -aG libvirt $(logname)
    else
        echo "$(logname) is already in libvirt group."
    fi
    if ! groups $(logname) | grep -q '\binput\b'; then
        sudo /usr/sbin/usermod -aG input $(logname)
    else
        echo "$(logname) is already in input group."
    fi

    # Step 5: Fetch macOS installer
    echo "Fetching macOS installer..."
    if [ -x "./fetch-macOS-v2.py" ]; then
        if [ ! -f "BaseSystem.dmg" ]; then
            ./fetch-macOS-v2.py
        else
            echo "macOS installer already fetched. Skipping."
        fi
    else
        echo "fetch-macOS-v2.py not found or not executable."
        exit 1
    fi

    # Step 6: Convert downloaded DMG to IMG
    echo "Converting BaseSystem.dmg to BaseSystem.img..."
    if [ -f "BaseSystem.dmg" ] && [ ! -f "BaseSystem.img" ]; then
        dmg2img -i BaseSystem.dmg BaseSystem.img
    else
        echo "BaseSystem.img already exists or BaseSystem.dmg not found. Skipping conversion."
    fi

    # Step 7: Create a virtual HDD image for macOS
    echo "Creating a virtual hard disk image in /home/rahul/VMS..."
    if [ ! -f "/home/rahul/VMS/mac_hdd_ng.img" ]; then
        mkdir -p /home/rahul/VMS  # Ensure the directory exists
        qemu-img create -f qcow2 /home/rahul/VMS/mac_hdd_ng.img 50G
    else
        echo "Virtual hard disk image already exists. Skipping creation."
    fi

    # Step 8: Start macOS installation using QEMU and OpenCore Boot script
    echo "Starting macOS installation using QEMU..."
    MY_OPTIONS="+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check"
    ALLOCATED_RAM="4096" # MiB
    CPU_SOCKETS="1"
    CPU_CORES="2"
    CPU_THREADS="4"
    REPO_PATH="."
    VMS_PATH="$HOME/VMS" # Path for the virtual HDD image
    OVMF_DIR="."

    args=(
      -enable-kvm -m "$ALLOCATED_RAM" -cpu Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,"$MY_OPTIONS"
      -machine q35
      -device qemu-xhci,id=xhci
      -device usb-kbd,bus=xhci.0 -device usb-tablet,bus=xhci.0
      -smp "$CPU_THREADS",cores="$CPU_CORES",sockets="$CPU_SOCKETS"
      -device usb-ehci,id=ehci
      -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
      -drive if=pflash,format=raw,readonly=on,file="$REPO_PATH/$OVMF_DIR/OVMF_CODE.fd"
      -drive if=pflash,format=raw,file="$REPO_PATH/$OVMF_DIR/OVMF_VARS-1920x1080.fd"
      -smbios type=2
      -device ich9-intel-hda -device hda-duplex
      -device ich9-ahci,id=sata
      -drive id=OpenCoreBoot,if=none,snapshot=on,format=qcow2,file="$REPO_PATH/OpenCore/OpenCore.qcow2"
      -device ide-hd,bus=sata.2,drive=OpenCoreBoot
      -device ide-hd,bus=sata.3,drive=InstallMedia
      -drive id=InstallMedia,if=none,file="$REPO_PATH/BaseSystem.img",format=raw
      -drive id=MacHDD,if=none,file="$VMS_PATH/mac_hdd_ng.img",format=qcow2
      -device ide-hd,bus=sata.4,drive=MacHDD
      -netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-net-pci,netdev=net0,id=net0,mac=52:54:00:c9:18:27
      -monitor stdio
      -device vmware-svga
    )

    qemu-system-x86_64 "${args[@]}"

    echo "Installation started. Use Disk Utility to partition and format the virtual disk as APFS."
    echo "Proceed with macOS installation."

    # Step 9: (Optional) Use with libvirt
    echo "For libvirt usage, follow the optional steps in the README.md file."

    echo "Setup complete. Please follow additional steps for configuration as needed."
}

# Main script execution
checkEnv
checkEscalationTool
setup_macos
