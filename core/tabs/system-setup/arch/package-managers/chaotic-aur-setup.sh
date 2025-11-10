#!/bin/sh -e

. ../../common-script.sh

installChaoticAUR() {
	case "$PACKAGER" in
	pacman)
		# Check if Chaotic-AUR is already installed
		if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
			# Print message indicating Chaotic-AUR is being installed
			printf "%b\n" "${YELLOW}Installing Chaotic-AUR repository...${RC}"
			# Call Escalation Tool and install and enable Chaotic-AUR
			"$ESCALATION_TOOL" pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
			"$ESCALATION_TOOL" pacman-key --lsign-key 3056513887B78AEB
			"$ESCALATION_TOOL" "$PACKAGER" -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
			"$ESCALATION_TOOL" "$PACKAGER" -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
			printf "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | "$ESCALATION_TOOL" tee -a /etc/pacman.conf
			"$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm
			# Print message indicating Chaotic-AUR has been installed and enabled
			printf "%b\n" "${GREEN}Chaotic-AUR repository installed and enabled${RC}"
		else
			# Print message indicating Chaotic-AUR is already installed
			printf "%b\n" "${GREEN}Chaotic-AUR repository already installed${RC}"
		fi
		;;
	*) # Print error message when linutil detects that user is not on Arch-based system
		printf "%b\n" "${RED}Chaotic-AUR is only supported on Arch-based systems${RC}"
		;;
	esac
}

checkEnv
checkEscalationTool
installChaoticAUR
