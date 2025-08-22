#!/bin/sh -e

. ../../common-script.sh

virtmanager() {
	setVMDetails

	case $distroInfo in
		*"arch"*)
			distro="archlinux" ;;
		*"debian"*)
			distro="debian""$(isoinfo -d -i "$isoFile" | awk 'NR==3{print $4}' | cut -f1 -d".")" ;;
		*"fedora"*)
			distro="fedora""${distroInfo##*-}" ;;
		*"opensuse"*)
			case $distroInfo in
				*"leap"*)
					distro="opensuse""${distroInfo##*-}" ;;
				*)
					distro="opensusetumbleweed" ;;
				esac ;;
		*"ubuntu"*)
			distro="Ubuntu""$(isoinfo -d -i "$isoFile" | awk 'NR==3{print $4}' | cut -f1,2 -d".")" ;;
		*) 
			case $windows in
				*"windows"*)
					distro="win11" ;;
				*)
					distro="unknown" ;;
			esac ;;
	esac

	printf "%b\n" "Please enter full folder path of for VM"
	read -r path

	# setup physical PCI/USB etc
	hostDev=""

	qemu-img create -f qcow2 "$path"/"$name".qcow2 "$driveSize""G"
	virt-install --name "$name" --memory="$memory" --vcpus="$vcpus" --cdrom "$isoFile" --os-variant "$distro" --disk "$path"/"$name".qcow2 "$hostDev"
}

qemu() {
	setVMDetails

	# Need to add PCI Graphics Passthrough

	qemu-img create -f qcow2 "$name".qcow2 "$driveSize""G"
	qemu-system-x86_64 \
		  -m "$memory"G \
		  -smp "$vcpus" \
		  -boot d \
		  -cdrom "$isoFile" \
		  -drive file="$name".qcow2,format=qcow2 \
		  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
		  -device e1000,netdev=net0 \
		  -display default,show-cursor=on \
		  -cpu host \
		  -enable-kvm \
		  -name "$name"
	
	printf "%b\n" "To run the VM after initial exit, use the command below"
	printf "%b\n" "qemu-system-x86_64 -m ${memory}G -smp ${vcpus} -drive file=${name}.qcow2,format=qcow2 \
			-netdev user,id=net0,hostfwd=tcp::2222-:22 -device e1000,netdev=net0 \
		  	-display default,show-cursor=on -smbios -enable-kvm -name ${name}"
	printf "%b\n" "To import this VM into virt-manager run the below"
	printf "virt-install --name ""${name}"" --memory=""${memory}"" --vcpus=""${vcpus}"" --os-variant ""${distro}"" --disk ""${path}""/""${name}"".qcow2 --network default --import"
}

libvirt() {
	#setVMDetails
	printf "%b\n" "${YELLOW}Libvirt is still under construction${RC}"
}

virtualbox(){
	setVMDetails

	case $distroInfo in
		*"arch"*)
			distro="ArchLinux" ;;
		*"debian"*)
			distro="Debian" ;;
		*"fedora"*)
			distro="Fedora" ;;
		*"opensuse"*)
			case $distroInfo in
				*"leap"*)
					distro="openSUSE_Leap" ;;
				*)
					distro="openSUSE_Tumbleweed" ;;
				esac ;;
		*"ubuntu"*)
			distro="Ubuntu" ;;
		*) 
			case $windows in
				*"windows"*)
					distro="Windows" ;;
				*)
					distro="Other Linux" ;;
			esac ;;
	esac

	if [ "$(dpkg --print-architecture)" = "amd64" ]; then
		arch="x86"
		subdistro="$distro""_64"
	elif [ "$(dpkg --print-architecture)" = "arm64" ]; then
		arch="arm"
		subdistro="$distro""_arm64"
	else
		printf "%b" "Architecture not supported"
	fi

	vboxmanage createvm --name="$name" --platform-architecture="$arch" --ostype="$distro" --register

	vboxmanage modifyvm "$name" --os-type="$subdistro" --memory="$memory" --chipset=piix3 --graphicscontroller=vmsvga --firmware=efi --acpi=on --ioapic=on --cpus="$vcpus" --cpu-profile=host --hwvirtex=on --apic=on --x86-x2apic=on --paravirt-provider=kvm --nested-paging=on --large-pages=off --x86-vtx-vpid=on --x86-vtx-ux=on --accelerate-3d=on --vram=256 --x86-long-mode=on --x86-pae=off
	vboxmanage modifyvm "$name" --mouse=usb --keyboard=ps2 --usb-ohci=on --usb-ehci=on --audio-enabled=on --audio-driver=default --audio-controller=ac97 --audio-codec=ad1980
	
	# Create SSH port for headless access after install (ssh -p 2522 username@10.0.2.15)
	vboxmanage modifyvm "$name" --nat-pf1 "SSH,tcp,127.0.0.1,2522,10.0.2.15,22"

	vboxmanage createmedium disk --filename="/home/""$USER""/VirtualBox VMs/""$name""/""$name"".vdi" --size="$driveSize" --variant=Standard --format=VDI

	vboxmanage storagectl "$name" --name "IDE" --add ide --controller piix4
	vboxmanage storagectl "$name" --name "SATA" --add sata --controller IntelAHCI

	vboxmanage storageattach "$name" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "/home/""$USER""/VirtualBox VMs/""$name""/""$name"".vdi"
	vboxmanage storageattach "$name" --storagectl "IDE" --port 0 --device 0 --type "$storageType" --medium "$isoFile"

	# Graphics Passthrough not available on VirtualBox 7.0 and newer yet. 

	# printf "%b\n" "${YELLOW}Do you want to pass through a GPU?${RC}"

	# if $passthtough == 1; then

	# 	printf "%b\n" "Please enter the Graphics Card model (ex. 5080, 4060, 9070, etc)"
	# 	read -r model
	# 	graphicsAdapters=$(lspci | grep -i vga | grep -i "$model")

	# 	SAVEIFS=$IFS
	# 	IFS=$'\n' 
	# 	graphicsAdapters=("$graphicsAdapters") 
	# 	IFS=$SAVEIFS

	# 	count=${#graphicsAdapters[@]}

	# 	if [[ "$count" -gt 1 ]]; then
	# 		graphicsAdapter=$(echo "$graphicsAdapters" | cut -f1 -d" ")
	# 	fi

	# 	graphicsAdapter=$($graphicsAdapters | cut -f1 -d" ")
	# 	vboxmanage modifyvm "$name" --pci-attach=$graphicsAdapter@01:05.0
	# fi

	vboxmanage startvm "$name"
}

setVMDetails() {
	# Set memory to 1/4 of host memnory
	totalMemory=$(grep MemTotal /proc/meminfo | tr -s ' ' | cut -d ' ' -f2)
	mem=$(("$totalMemory" / 1024000 + 1))
	memory=$(("$mem" / 4))
	if [ "$memory" -lt "2" ]; then
		memory="2"
	fi
	memory=$(("$memory" * 1024))

	totalCpus=$(getconf _NPROCESSORS_ONLN)
	vcpus=$(("$totalCpus" / 4))
	if [ "$vcpus" -lt "2" ]; then
		vcpus="2"
	fi

	while true 
	do
		printf "%b\n" "Please enter VM Name"
		read -r name
		
		if ! checkVMExists; then
			break
		else
			printf "%b\n" "VM with that name already exists"
		fi
	done

	printf "%b\n" "Please enter drive size"
	read -r driveSize

	printf "%b\n" "Please enter full iso path"
	read -r isoFile

	case $isoFile in
		*".iso")
			storageType=dvddrive

			if ! command_exists isoinfo; then
				installIsoInfo	
			fi

			distroInfo=$(isoinfo -d -i "$isoFile" | grep -i "volume id:" | awk '{print $3}'  | tr '[:upper:]' '[:lower:]')
			windows=$(isoinfo -d -i "$isoFile" | grep -i "Publisher id:" | awk '{print $3, $4}') ;;
		*)
			storageType=hdd ;;
	esac
}

installIsoInfo() {
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

checkVMExists() {

	if [ "$hypervisor" = "virt-manager" ]; then
		vmExists=$(virsh list --all | grep -i "$name" | awk '{print $2}')
	elif [ "$hypervisor" = "virtualbox" ]; then
		vmExists=$(vboxmanage list vms | grep -i \""$name"\" | cut -f1 -d" ")
	fi

	if [ -z "$vmExists" ]; then
		return 1
	else
		return 0
	fi
}

checkInstalled() {
	hypervisor=$1

	if command_exists "$hypervisor"; then
		if [ "$hypervisor" = "virt-manager" ]; then
			virtmanager
		elif [ "$hypervisor" = "qemu-img" ]; then
			qemu
		else
        	$hypervisor
        fi
    else
        printf "%b\n" "${GREEN}${hypervisor} is not installed.${RC}"
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
    read -r -r CHOICE
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