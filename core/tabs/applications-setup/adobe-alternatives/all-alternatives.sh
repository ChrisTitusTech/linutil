#!/usr/bin/env bash

# Photoshop/Lightroom Alternatives

gimp() {
	printf "%b\n" "${YELLOW}Installing GIMP...${RC}"
	if ! command_exists gimp; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y gimp
	            ;;
	        pacman)
			    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm gimp
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.gimp.GIMP
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}GIMP is already installed.${RC}"
	fi
}

pinta() {
	printf "%b\n" "${YELLOW}Installing Pinta...${RC}"
	if ! command_exists mypaint; then
	    case "$PACKAGER" in
	        dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y pinta
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive com.github.PintaProject.Pinta
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Pinta is already installed.${RC}"
	fi
}

darktable() {
	printf "%b\n" "${YELLOW}Installing Darktable...${RC}"
	if ! command_exists darktable; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y darktable
	            ;;
	        pacman)
			    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm darktable
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.darktable.Darktable
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Darktable is already installed.${RC}"
	fi
}

krita() {
	printf "%b\n" "${YELLOW}Installing Krita...${RC}"
	if ! command_exists krita; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y krita
	            ;;
	        pacman)
			    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm krita
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.kde.krita
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Krita is already installed.${RC}"
	fi
}

mypaint() {
	printf "%b\n" "${YELLOW}Installing MyPaint...${RC}"
	if ! command_exists mypaint; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y mypaint
	            ;;
	        pacman)
			    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm mypaint
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.mypaint.MyPaint
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}MyPaint is already installed.${RC}"
	fi
}

# Illistrator Alternatives

inkscape() {
	printf "%b\n" "${YELLOW}Installing Inkscape...${RC}"
	if ! command_exists inkscape; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y inkscape
	            ;;
	        pacman)
			    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm inkscape
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.inkscape.Inkscape
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Inkscape is already installed.${RC}"
	fi
}

graphite() {
	# Coming Soon
}


# InDesign Alternatives

scribus() {
	printf "%b\n" "${YELLOW}Installing Scribus...${RC}"
	if ! command_exists scribus; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y scribus
	            ;;
	        pacman)
			    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm scribus
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive net.scribus.Scribus
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Scribus is already installed.${RC}"
	fi
}


# Premier Alternatives

openshot() {
	printf "%b\n" "${YELLOW}Installing OpenShot...${RC}"
	if ! command_exists openshot; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y openshot-qt
	            ;;
	        pacman)
			    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm openshot
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.openshot.OpenShot
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}OpenShot is already installed.${RC}"
	fi
}

olive() {
	printf "%b\n" "${YELLOW}Installing Olive Video Editor...${RC}"
	if ! command_exists openshot; then
	    case "$PACKAGER" in
	        dnf)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y olive
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.olivevideoeditor.Olive
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Olive Video Editor is already installed.${RC}"
	fi
}

davinchiResolve() {

}


# Animate Alternatives

synfig() {
	printf "%b\n" "${YELLOW}Installing Synfig...${RC}"
	if ! command_exists synfig; then
	    case "$PACKAGER" in
	        dnf)
	        	"$ESCALATION_TOOL" "$PACKAGER" install -y synfigstudio
	        	;;
	        pacman)
			    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm synfigstudio
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.synfig.SynfigStudio
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Synfig Studio is already installed.${RC}"
	fi
}


# After Effects Alternatives

natron() {
	printf "%b\n" "${YELLOW}Installing Natron...${RC}"
	if ! command_exists natron; then
		"$ESCALATION_TOOL" flatpak install --noninteractive fr.natron.natron
	else
		printf "%b\n" "${GREEN}Natron is already installed.${RC}"
	fi
}

blender() {
	printf "%b\n" "${YELLOW}Installing Blender...${RC}"
	if ! command_exists blender; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y blender
	            ;;
	        pacman)
			    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm blender
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.blender.Blender
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Blender is already installed.${RC}"
	fi
}


# Audition Alternatives

ardour() {
	printf "%b\n" "${YELLOW}Installing Ardour...${RC}"
	if ! command_exists ardour; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y ardour
	            ;;
	        pacman)
			    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm ardour
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.ardour.Ardour
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Ardour is already installed.${RC}"
	fi
}

audacity() {
	printf "%b\n" "${YELLOW}Installing Audacity...${RC}"
	if ! command_exists audacity; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" install -y audacity
	            ;;
	        pacman)
			    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm audacity
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.audacityteam.Audacity
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Audacity is already installed.${RC}"
	fi
}

tenacity() {
	printf "%b\n" "${YELLOW}Installing Tenacity...${RC}"
	if ! command_exists audacity; then
	    case "$PACKAGER" in
	        pacman)
			    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm tenacity
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive org.tenacityaudio.Tenacity
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Tenacity is already installed.${RC}"
	fi
}

# Media Encoder

handbrake() {
	printf "%b\n" "${YELLOW}Installing Handbrake...${RC}"
	if ! command_exists handbrake; then
	    case "$PACKAGER" in
	        apt-get|nala)
				"$ESCALATION_TOOL" "$PACKAGER" install -y handbrake
	            ;;
	        pacman)
			    "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm handbrake
	            ;;
	        *)
	            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
	            "$ESCALATION_TOOL" flatpak install --noninteractive fr.handbrake.ghb
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Handbrake is already installed.${RC}"
	fi
}