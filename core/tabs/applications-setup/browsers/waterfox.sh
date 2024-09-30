#!/bin/sh -e


. ../../common-script.sh


buildWaterfox() {
    wget -O waterfox.tar.bz2 "https://cdn1.waterfox.net/waterfox/releases/latest/linux" && tar -xvjf waterfox.tar.bz2 -C ./ && rm waterfox.tar.bz2 ; sudo mkdir -p /opt/waterfox && sudo mv waterfox /opt/waterfox && cd /opt/waterfox/waterfox && sudo ln -s /opt/waterfox/waterfox/waterfox /usr/bin/waterfox
}


installWaterfox() {
    if ! command_exists waterfox; then
	printf "%b\n" "${YELLOW}Installing waterfox...${RC}"
	case "$PACKAGER" in
	    apt-get|nala)
		"$ESCALATION_TOOL" "$PACKAGER" install -y wget && buildWaterfox
		;;
		zypper)
		    "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install wget && buildWaterfox
	        ;;
	    pacman)
		"$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm wget && buildWaterfox
		;;
	    dnf)
	      "$ESCALATION_TOOL" "$PACKAGER" install -y wget && buildWaterfox
	      ;;
	  *)
	      printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	      exit 1
	      ;;
esac
    else
	printf "%b\n" "${GREEN}waterfox is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installWaterfox
