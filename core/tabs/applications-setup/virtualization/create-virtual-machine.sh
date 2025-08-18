#!/bin/sh -e

. ../../common-script.sh

virt-manager() {
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

	# Need to add PCI Graphics Passthrough

	virt-install --name "$name" --memory=$memory --vcpus=$vcpus --location $isoFile --osvariant $distro --disk size=$driveSize
}

qemu() {
	setVMDetails

	# Need to add PCI Graphics Passthrough

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

libvirt() {
	#setVMDetails
	printf "%b\n" "${YELLOW}Libvirt is still under construction${RC}"
}

virtualbox(){
	setVMDetails

	if [[ "${distroInfo,,}" == *"ARCH"* ]] || [[ "$distroInfo" == *"ARCH"* ]]  ; then
		distro="ArchLinux"
	elif [[ "${distroInfo,,}" == *"Debian"* ]] || [[ "$distroInfo" == *"Debian"* ]] ; then
		distro="Debian"
	elif [[ "${distroInfo,,}" == *"Fedora"* ]] || [[ "$distroInfo" == *"Fedora"* ]]; then
		distro="Fedora"
	elif [[ "${distroInfo,,}" == *"openSUSE"* ]] || [[ "$distroInfo" == *"openSUSE"* ]]; then
		if [[ "${distroInfo,,}" == *"Leap"* ]] || [[ "$distroInfo" == *"Leap"* ]]; then
			distro="openSUSE_Leap"
		else
			distro="openSUSE_Tumbleweed"
		fi
	elif [[ "${distroInfo,,}" == *"Ubuntu"* ]] || [[ "$distroInfo" == *"Ubuntu"* ]]; then
		distro="Ubuntu"
	elif [[ "$windows" == *"MICROSOFT"* ]] || [[ "$distroInfo" == *"MICROSOFT"* ]]; then
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
	
	# Create SSH port for headless access after install (ssh -p 2522 username@10.0.2.15)
	vboxmanage modifyvm "$name" --nat-pf1 "SSH,tcp,127.0.0.1,2522,10.0.2.15,22"

	vboxmanage createmedium disk --filename="/home/$USER/VirtualBox VMs/$name/$name.vdi" --size=$driveSize --variant=Standard --format=VDI

	vboxmanage storagectl "$name" --name "IDE" --add ide --controller piix4
	vboxmanage storagectl "$name" --name "SATA" --add sata --controller IntelAHCI

	vboxmanage storageattach "$name" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "/home/$USER/VirtualBox VMs/$name/$name.vdi"
	vboxmanage storageattach "$name" --storagectl "IDE" --port 0 --device 0 --type $storageType --medium "$isoFile"

	# Graphics Passthrough not available on VirtualBox 7.0 and newer. 

	# printf "%b\n" "${RED}Only use this option if a second graphics adapter for your host machine${RC}"
	# printf "%b\n" "${YELLOW}Do you want to pass through a GPU?${RC}"
	# yes_or_no

	# passthtough=$?

	# if $passthtough == 1; then

	# 	printf "%b\n" "Please enter the Graphics Card model (ex. 5080, 4060, 9070, etc)"
	# 	read model
	# 	graphicsAdapters=$(lspci | grep -i vga | grep -i $model)

	# 	SAVEIFS=$IFS
	# 	IFS=$'\n' 
	# 	graphicsAdapters=($graphicsAdapters) 
	# 	IFS=$SAVEIFS

	# 	count=${#graphicsAdapters[@]}

	# 	if [[ "$count" -gt 1 ]]; then
	# 		graphicsAdapter=$(echo graphicsAdapters | cut -f1 -d" ")
	# 	fi

	# 	graphicsAdapter=$(echo graphicsAdapters | cut -f1 -d" ")
	# 	vboxmanage modifyvm "$name" --pci-attach=$graphicsAdapter@01:05.0
	# fi

	printf "b%\n" "Do you want to start the $name"
	yes_or_no

	startvm=$?

	if $startvm == 1; then
		vboxmanage startvm $name
	fi
}

setVMDetails() {
	# Set memory to 1/4 of host memnory
	totalMemory=$(grep MemTotal /proc/meminfo | tr -s ' ' | cut -d ' ' -f2)
	mem=$(expr $(expr $totalMemory / 1024000) + 1)
	memory=$(expr $mem / 4)
	if [ "$memory" -lt "2" ]; then
		memory=2
	fi
	memory=$(expr $memory \* 1024)ory

	totalCpus=$(getconf _NPROCESSORS_ONLN)
	vcpus=$(expr $totalCpus / 4)
	if [ "$vcpus" -lt "2" ]; then
		vcpus=2
	fi

	while true 
	do
		printf "%b\n" "Please enter VM Name"
		read name

		vmExists=$(vboxmanage list vms | grep -i \"$name\")
		if [[ -z $vmExists ]]; then
			break
		else
			printf "%b\n" "VM with that name already exists"
		fi
	done

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
	$hypervisor=$1

	if command_exists $hypervisor; then
        $hypervisor
    else
        printf "%b\n" "${GREEN}$hypervisor is not installed.${RC}"
        exit 1
    fi
}

main() {
	printf "%b\n" "${YELLOW}Memory, CPU, OS/Distro are automatically determined${RC}"
	printf "%b\n" "${YELLOW}Choose tool to create Virtual Machine:${RC}"
    printf "%b\n" "1. ${YELLOW}Virtual-Manager${RC}"
    printf "%b\n" "2. ${YELLOW}QEMU${RC}"
    printf "%b\n" "3. ${YELLOW}VirtualBox${RC}"
    # printf "%b\n" "4. ${YELLOW}Libvirt${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) checkInstalled virt-manager ;;
        2) checkInstalled qemu-img ;;
        3) checkInstalled virtualbox ;;
        # 4) checkInstalled libvirt ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main