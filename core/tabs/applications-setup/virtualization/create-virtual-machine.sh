#!/bin/sh -e

. ../../common-script.sh

createVirtManagerVM() {
	setVMDetails

	if [[ "$distroInfo" ~= *"ARCH"* ]]; then
		distro="archlinux"
	elif [[ "$distroInfo" ~= *"Debian"* ]]; then
		distro="debian""$(isoinfo -d -i $isoFile | awk 'NR==3{print $4}' | cut -f1 -d".")"
	elif [[ "$distroInfo" ~= *"Fedora"* ]]; then
		distro="fedora""$(echo "${distroInfo##*-}")"
	elif [[ "$distroInfo" ~= *"openSUSE"* ]]; then
		if [[ "$distroInfo" ~= *"Leap"* ]]; then
			distro="opensuse""$(echo "${distroInfo##*-}")"
		else
			distro="opensusetumbleweed"
		fi
	elif [[ "$distroInfo" ~= *"Ubuntu"* ]]; then
		distro="Ubuntu""$(isoinfo -d -i $isoFile | awk 'NR==3{print $4}' | cut -f1,2 -d".")"
	elif [[ "$windows" ~= *"MICROSOFT"* ]]; then
		distro="Windows"
	else 
		distro="Other Linux"
	fi

	virt-install --name "$name" --memory=$memory --vcpus=$vcpus --location $isoFile --osvariant $distro --disk size=$driveSize
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
	
	printf "%b\n" "Run the below to launch new VM"
	printf "%b\n" "qemu-system-x86_64 \
		  -m "$memory"G \
		  -smp $vcpus \
		  -drive file=$name.qcow2,format=qcow2 \
		  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
		  -device e1000,netdev=net0 \
		  -display default,show-cursor=on"
}

createLibvirtVM() {
	#setVMDetails
	printf "%b\n" "${YELLOW}Libvirt is still under construction${RC}"
}

createVBoxVM(){
	setVMDetails

	if [[ "$distroInfo" ~= *"ARCH"* ]]; then
		distro="ArchLinux"
	elif [[ "$distroInfo" ~= *"Debian"* ]]; then
		distro="Debian"
	elif [[ "$distroInfo" ~= *"Fedora"* ]]; then
		distro="Fedora"
	elif [[ "$distroInfo" ~= *"openSUSE"* ]]; then
		if [[ "$distroInfo" ~= *"Leap"* ]]; then
			distro="openSUSE_Leap"
		else
			distro="openSUSE_Tumbleweed"
		fi
	elif [[ "$distroInfo" ~= *"Ubuntu"* ]]; then
		distro="Ubuntu"
	elif [[ "$windows" ~= *"MICROSOFT"* ]]; then
		distro="Windows"
	else 
		distro="Other Linux"
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

	vboxmanage createvm --name="$name" --platform-architecture=$arch --ostype="$distro" --register

	vboxmanage modifyvm "$name" --os-type=$subdistro --memory=$memory --chipset=piix3 --graphicscontroller=vmsvga --firmware=efi --acpi=on --ioapic=on --cpus=$vcpus --cpu-profile=host --hwvirtex=on --apic=on --x86-x2apic=on --paravirt-provider=kvm --nested-paging=on --large-pages=off --x86-vtx-vpid=on --x86-vtx-ux=on --accelerate-3d=on --vram=256 --x86-long-mode=on --x86-pae=off
	vboxmanage modifyvm "$name" --mouse=usb --keyboard=ps2 --usb-ohci=on --usb-ehci=on --audio-enabled=on --audio-driver=default --audio-controller=ac97 --audio-codec=ad1980

	vboxmanage createmedium disk --filename="/media/namato/Data/Virtual Machines/$name/$name.vdi" --size=$driveSize --variant=Standard --format=VDI

	vboxmanage storagectl "$name" --name "IDE" --add ide --controller piix4
	vboxmanage storagectl "$name" --name "SATA" --add sata --controller IntelAHCI

	vboxmanage storageattach "$name" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$name.vdi"
	vboxmanage storageattach "$name" --storagectl "IDE" --port 0 --device 0 --type $storageType --medium "$isoFile"
}

setVMDetails() {
	# Set memory to 1/4 of host memnory
	mem=$(grep MemTotal /proc/meminfo | tr -s ' ' | cut -d ' ' -f2)
	mem=$(expr $(expr $mem / 1024000) + 1)
	memory=$(expr $mem / 4)
	if [ "$memory" -lt "4" ]; then
		memory=4
	fi
	memory=$(expr $memory \* 1024)

	cpus=$(getconf _NPROCESSORS_ONLN)
	vcpus=$(expr $cpu / 4)
	if [ "$vcpus" -lt "2" ]; then
		vcpus=2
	fi

	printf "%b\n" "Please enter VM Name"
	read name

	printf "%b\n" "Please enter drive size (virtualbox in MB. virt-manage in GB)"
	read driveSize

	printf "%b\n" "Please enter full iso path"
	read isoFile

	if [[ $isoFile ~= *".iso" ]]; then
		storageType=dvddrive

		if ! command_exists isoinfo; then
			installIsoInfo	
		fi

		distroInfo=$(isoinfo -d -i $isoFile | awk 'NR==3{print $3}')
		windows=$(isoinfo -d -i $isoFile | awk 'NR==5{print $3, $4}')
	else
		storageType=hdd
	fi

	# Variable Not Used as of 2025/08/13
	if [[ "$distro" == "Windows11" ]]; then
		os="Windows"
	else
		os="Linux"
	fi
}

installIsoInfo(){
	printf "%b\n" "${YELLOW}Installing Gnome Boxes...${RC}"
    case "$PACKAGER" in
        apt-get|nala|dnf|zypper)
            "$ESCALATION_TOOL" "$PACKAGER" -y install genisoimage
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            ;;
    esac
}

checkInstalled() {

	if ! command_exists $hypervisor; then
        runCreateVM
    else
        printf "%b\n" "${GREEN}$hypervisor is not installed.${RC}"
        exit 1
    fi
}

runCreateVM() {

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
	printf "%b\n" "${YELLOW}Memory, CPU, OS/Distro are automatically determined${RC}"
	printf "%b\n" "${YELLOW}Choose tool to create Virtual Machine:${RC}"
    printf "%b\n" "1. ${YELLOW}Virtual-Manager${RC}"
    printf "%b\n" "2. ${YELLOW}QEMU${RC}"
    printf "%b\n" "3. ${YELLOW}VirtualBox${RC}"
    printf "%b\n" "3. ${YELLOW}Libvirt${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) checkInstalled virt-manager ;;
        2) checkInstalled qemu-img ;;
        3) checkInstalled virtualbox ;;
        4) checkInstalled libvirt ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main