#!/bin/sh -e

. ../common-script.sh

gitpath="$HOME/.local/share/mybash"

cloneMyBash() {
    # Check if the dir exists before attempting to clone into it.
    if [ -d "$gitpath" ]; then
        rm -rf "$gitpath"
    fi
    mkdir -p "$HOME/.local/share" # Only create the dir if it doesn't exist.
    cd "$HOME" && git clone https://github.com/ChrisTitusTech/mybash.git "$gitpath"
}

installDepend() {
    echo "Install mybash if not already installed"
    case "$PACKAGER" in
        pacman)
            $ESCALATION_TOOL "$PACKAGER" -S --needed --noconfirm bash bash-completion tar bat tree unzip fontconfig
            ;;
        apt)
            $ESCALATION_TOOL "$PACKAGER" install -y bash bash-completion tar bat tree unzip fontconfig
            ;;
        dnf)
            $ESCALATION_TOOL "$PACKAGER" install -y bash bash-completion tar bat tree unzip fontconfig
            ;;
        zypper)
            $ESCALATION_TOOL "$PACKAGER" install -y bash bash-completion tar bat tree unzip fontconfig
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}" # The packages above were grabbed out of the original mybash-setup-script.
            exit 1
            ;;
    esac
}

installFont() {
    # Check to see if the MesloLGS Nerd Font is installed (Change this to whatever font you would like)
    FONT_NAME="MesloLGS Nerd Font Mono"
    if fc-list :family | grep -iq "$FONT_NAME"; then
        echo "Font '$FONT_NAME' is installed."
    else
        echo "Installing font '$FONT_NAME'"
        # Change this URL to correspond with the correct font
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
        FONT_DIR="$HOME/.local/share/fonts"
        TEMP_DIR=$(mktemp -d)
        curl -sSLo "$TEMP_DIR"/"${FONT_NAME}".zip "$FONT_URL"
        unzip "$TEMP_DIR"/"${FONT_NAME}".zip -d "$TEMP_DIR"
        mkdir -p "$FONT_DIR"/"$FONT_NAME"
        mv "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT_NAME"
        fc-cache -fv
        rm -rf "${TEMP_DIR}"
        echo "'$FONT_NAME' installed successfully."
    fi
}

installStarshipAndFzf() {
    if command_exists starship; then
        echo "Starship already installed"
        return
    fi

    if ! curl -sSL https://starship.rs/install.sh | sh; then
        printf "%b\n" "${RED}Something went wrong during starship install!${RC}"
        exit 1
    fi
    if command_exists fzf; then
        echo "Fzf already installed"
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        $ESCALATION_TOOL ~/.fzf/install
    fi
}

installZoxide() {
    if command_exists zoxide; then
        echo "Zoxide already installed"
        return
    fi

    if ! curl -sSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
        printf "%b\n" "${RED}Something went wrong during zoxide install!${RC}"
        exit 1
    fi
}

linkConfig() {
    OLD_BASHRC="$HOME/.bashrc"
    if [ -e "$OLD_BASHRC" ] && [ ! -e "$HOME/.bashrc.bak" ]; then
        printf "%b\n" "${YELLOW}Moving old bash config file to $HOME/.bashrc.bak${RC}"
        if ! mv "$OLD_BASHRC" "$HOME/.bashrc.bak"; then
            printf "%b\n" "${RED}Can't move the old bash config file!${RC}"
            exit 1
        fi
    fi

    printf "%b\n" "${YELLOW}Linking new bash config file...${RC}"
    ln -svf "$gitpath/.bashrc" "$HOME/.bashrc" || {
        printf "%b\n" "${RED}Failed to create symbolic link for .bashrc${RC}"
        exit 1
    }
    ln -svf "$gitpath/starship.toml" "$HOME/.config/starship.toml" || {
        printf "%b\n" "${RED}Failed to create symbolic link for starship.toml${RC}"
        exit 1
    }
    printf "%b\n" "${GREEN}Done! restart your shell to see the changes.${RC}"
}

checkEnv
checkEscalationTool
cloneMyBash
installDepend
installFont
installStarshipAndFzf
installZoxide
linkConfig