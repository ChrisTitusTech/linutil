#!/bin/sh -e

. ../../common-script.sh

createVirtManagerVM() {
	setVMDetails
	virt-install --name "$name" --memory=$memory --vcpus=$vcpus --location $isoFile --os-type $os --osVariant $distro --disk size=$driveSize --network network=default
}

createQEMUVM() {
	setVMDetails

	qemu-img create -f qcow2 $name.qcow2 $driveSize
	qemu-system-x86_64 \
		  -m "$memory"G \
		  -smp $vcpus \
		  -boot d \
		  -cdrom $isoFile \
		  -drive file=$name.qcow2,format=qcow2 \
		  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
		  -device e1000,netdev=net0 \
		  -display default,show-cursor=on
	qemu-system-x86_64 \
		  -m "$memory"G \
		  -smp $vcpus \
		  -drive file=$name.qcow2,format=qcow2 \
		  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
		  -device e1000,netdev=net0 \
		  -display default,show-cursor=on
}

createLibvirtVM() {
	setVMDetails
}

createVBoxVM(){
	setVMDetails

	memory=$(expr $memory \* 1024)
	vboxmanage createvm --name="$name" --platform-architecture=$arch --ostype="$distro" --register

	vboxmanage modifyvm "$name" --os-type=$subdistro --memory=$memory --chipset=piix3 --graphicscontroller=vmsvga --firmware=efi --acpi=on --ioapic=on --cpus=$vcpus --cpu-profile=host --hwvirtex=on --apic=on --x86-x2apic=on --paravirt-provider=kvm --nested-paging=on --large-pages=off --x86-vtx-vpid=on --x86-vtx-ux=on --accelerate-3d=on --vram=256 --x86-long-mode=on --x86-pae=off
	vboxmanage modifyvm "$name" --mouse=usb --keyboard=ps2 --usb-ohci=on --usb-ehci=on --audio-enabled=on --audio-driver=default --audio-controller=ac97 --audio-codec=ad1980

	vboxmanage createmedium disk --filename="/media/namato/Data/Virtual Machines/$name/$name.vdi" --size=$driveSize --variant=Standard --format=VDI

	vboxmanage storagectl "$name" --name "IDE Controller" --add ide --controller piix4
	vboxmanage storagectl "$name" --name "SATA Controller" --add sata --controller IntelAHCI

	vboxmanage storageattach "$name" --storagectl "IDE Controller" --port 0 --device 0 --type $storageType --medium "$isoFile"
	vboxmanage storageattach "$name" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$name.vdi"
}

setVMDetails() {
	mem=$(grep MemTotal /proc/meminfo | tr -s ' ' | cut -d ' ' -f2)
	mem=$(expr $(expr $mem / 1024000) + 1)
	memory=$(expr $mem / 4)
	if [ "$memory" -lt "4" ]; then
		memory=4
	fi

	cpus=$(getconf _NPROCESSORS_ONLN)
	vcpus=$(expr $cpu / 4)
	if [ "$vcpus" -lt "2" ]; then
		vcpus=2
	fi

	printf "%b\n" "Please enter VM Name"
	read name

	printf "%b\n" "Please enter drive size (virtualbox in MB. virt-manage in GB)"
	read driveSize

	printf "%b\n" "Please enter full iso/drive path"
	read isoFile

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
	printf "%b\n" "10. Enter Distro Name"
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
	    10) read distro ;;

	    *) printf "%b\n" "Invalid choice." && exit 1 ;;
	esac

	if [[ "$distro" == "openSUSE" ]]; then
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

	if [[ "$distro" == "Windows11" ]]; then
		os="Windows"
	else
		os="Linux"
	fi

	if [[ "$(dpkg --print-architecture)" == "amd64" ]]; then
		arch="x86"
		subdistro="$distro""_64"
	elif [[ "$(dpkg --print-architecture)" == "arm64" ]]; then
		arch="arm"
		subdistro="$distro""_arm64"
	else
		printf "%b" "Architecture not supported"
	fi

	if [[ $isoFile ~= *".iso" ]]; then
		storageType=dvddrive
	else
		storageType=hdd
	fi
}

checkInstalled() {
	hypervisor=$1

	printf "%b\n" "${YELLOW}Check if $ ${RC}"
    case "$PACKAGER" in
        apt-get|nala)
        	if ! command_exists $hypervisor; then
		        runCreateVM $hypervisor
		    else
		        printf "%b\n" "${GREEN}$hypervisor is not installed.${RC}"
		        exit 1
		    fi
            ;;
        dnf)
            if ! command_exists $hypervisor; then
		        runCreateVM $hypervisor
		    else
		        printf "%b\n" "${GREEN}$hypervisor is not installed.${RC}"
		        exit 1
		    fi
            ;;
        zypper)
            if ! command_exists virt-manager; then
		        runCreateVM $hypervisor
		    else
		        printf "%b\n" "${GREEN}$hypervisor is not installed.${RC}"
		        exit 1
		    fi
            ;;
        pacman)
        	if ! command_exists virt-manager; then
		        runCreateVM $hypervisor
		    else
		        printf "%b\n" "${GREEN}$hypervisor is not installed.${RC}"
		        exit 1
		    fi
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
}

runCreateVM() {
	hypervisor=$1

	if "$hypervisor" == "virt-manager"; then
		createVirtManagerVM
	elif "$hypervisor" == "qemu-img"; then
		createQEMUVM
	elif "$hypervisor" == "libvirt"; then
		createLibvirtVM
	elif "$hypervisor" == "virtualbox"; then
		createVBoxVM
	else
		printf "%b\n" "hypervisor not supported"
	fi

}

main() {
	printf "%b\n" "${YELLOW}Choose tool to create Virtual Machine:${RC}"
    printf "%b\n" "1. ${YELLOW}Virtual-Manager${RC}"
    printf "%b\n" "2. ${YELLOW}QEMU${RC}"
    printf "%b\n" "3. ${YELLOW}Libvirt${RC}"
    printf "%b\n" "4. ${YELLOW}VirtualBox${RC}"
    printf "%b" "Enter your choice [1-5]: "
    read -r CHOICE
    case "$CHOICE" in
        1) checkInstalled virt-manager ;;
        2) checkInstalled qemu-img ;;
        3) checkInstalled libvirt ;;
        4) checkInstalled virtualbox ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main