#!/bin/sh

. ../../common-script.sh
. ../../common-service-script.sh

install_dwm_titus() {
    printf "%b\n" "${YELLOW}Installing DWM-Titus...${RC}"
    
    DWM_DIR="$HOME/.local/share/dwm-titus"
    
    # Create directory if needed
    [ ! -d "$HOME/.local/share" ] && mkdir -p "$HOME/.local/share/"
    
    # Clone or update dwm-titus repository
    if [ ! -d "$DWM_DIR" ]; then
        printf "%b\n" "${YELLOW}Cloning dwm-titus repository...${RC}"
        git clone https://github.com/ChrisTitusTech/dwm-titus.git "$DWM_DIR" || {
            printf "%b\n" "${RED}Failed to clone dwm-titus${RC}"
            return 1
        }
    else
        printf "%b\n" "${YELLOW}Updating dwm-titus repository...${RC}"
        cd "$DWM_DIR" && git pull || {
            printf "%b\n" "${RED}Failed to update dwm-titus${RC}"
            return 1
        }
    fi
    
    # Run the upstream install script
    printf "%b\n" "${YELLOW}Running dwm-titus installer...${RC}"
    bash "$DWM_DIR/install.sh" || {
        printf "%b\n" "${RED}dwm-titus installation failed${RC}"
        return 1
    }
    
    printf "%b\n" "${GREEN}DWM-Titus installation complete${RC}"
}

checkEnv
install_dwm_titus
