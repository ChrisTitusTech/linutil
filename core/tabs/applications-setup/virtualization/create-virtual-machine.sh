#!/bin/sh -e

. ../../common-script.sh

createVBoxVM(){
	echo "Please enter VM Name"
	read name

	printf "%b\n" "Select Distro:"
	printf "%b\n" "1. ArchLinux"
	printf "%b\n" "2. Debian"
	printf "%b\n" "3. Fedora"
	printf "%b\n" "4. Gentoo"
	printf "%b\n" "5. Oracle Linux"
	printf "%b\n" "6. Red Hat"
	printf "%b\n" "7. openSUSE"
	printf "%b\n" "8. Ubuntu"
	printf "%b\n" "9. Windows 11"
	printf "%b\n" "10. Other"
	printf "%b" "Enter your choice [1-10]: "
	read -r CHOICE
	case "$CHOICE" in
	    1) 	distro="ArchLinux" ;;
	    2) 	distro="Debian" ;;
	    3) 	distro="Fedora" ;;
	    4) 	distro="Gentoo" ;;
	    5) 	distro="Oracle" ;;
	    6) 	distro="Red Hat" ;;
	    7) 	distro="openSUSE" ;;
	    8) 	distro="Ubuntu" ;;
		9)	distro="Windows11" ;;
	    10) distro="Other" ;;

	    *) printf "%b\n" "Invalid choice." && exit 1 ;;
	esac

	if [[ "$distro" = "openSUSE" ]]; then
		printf "%b\n" "Select openSUSE Version:"
		printf "%b\n" "1. Leap"
		printf "%b\n" "2. Tumbleweed"
		printf "%b" "Enter your choice [1-2]: "
		read -r CHOICE2
		case "$CHOICE2" in
		    1) 	distro="openSUSE_Leap" ;;
		    2) 	distro="openSUSE_Tumbleweed" ;;
		*) printf "%b\n" "Invalid choice." && exit 1 ;;
		esac
	fi

	if [[ "$(dpkg --print-architecture)" == "amd64" ]]; then
		arch="x86"
		subdistro="$distro""_64"
	elif [[ "$(dpkg --print-architecture)" == "arm64" ]]; then
		arch="arm"
		subdistro="$distro""_arm64"
	fi

	vboxmanage createvm --name="$name" --platform-architecture=$arch --ostype="$distro" --register

	vboxmanage modifyvm "$name" --os-type=$subdistro --memory=4096 --chipset=piix3 --graphicscontroller=vmsvga --firmware=efi --acpi=on --ioapic=on --cpus=4 --cpu-profile=host --hwvirtex=on --apic=on --x86-x2apic=on --paravirt-provider=kvm --nested-paging=on --large-pages=off --x86-vtx-vpid=on --x86-vtx-ux=on --accelerate-3d=on --vram=256 --x86-long-mode=on --x86-pae=off
	vboxmanage modifyvm "$name" --mouse=usb --keyboard=ps2 --usb-ohci=on --usb-ehci=on --audio-enabled=on --audio-driver=default --audio-controller=ac97 --audio-codec=ad1980

	vboxmanage createmedium disk --filename="/media/namato/Data/Virtual Machines/$name/$name.vdi" --size=100000 --variant=Standard --format=VDI

	vboxmanage storagectl "$name" --name "IDE Controller" --add ide --controller piix4
	vboxmanage storagectl "$name" --name "SATA Controller" --add sata --controller IntelAHCI

	vboxmanage storageattach "$name" --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium "/media/namato/Data/Virtual Machines/usbboot.vmdk"
	vboxmanage storageattach "$name" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium emptydrive
	vboxmanage storageattach "$name" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "/media/namato/Data/Virtual Machines/$name/$name.vdi"
}

main() {
	printf "%b\n" "${YELLOW}Choose tool to create Virtual Machine:${RC}"
    printf "%b\n" "1. ${YELLOW}Virtual-Manager${RC}"
    printf "%b\n" "2. ${YELLOW}QEMU${RC}"
    printf "%b\n" "3. ${YELLOW}Libvirt${RC}"
    printf "%b\n" "4. ${YELLOW}VirtualBox${RC}"
    printf "%b\n" "5. ${YELLOW}Gnome Boxes${RC}"
    printf "%b" "Enter your choice [1-5]: "
    read -r CHOICE
    case "$CHOICE" in
        1) createVirtManagerVM ;;
        2) createQEMUVM ;;
        3) createLibvirtVM ;;
        4) createVBoxVM ;;
        5) createGnomeBoxVM;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main