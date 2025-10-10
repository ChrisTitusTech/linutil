#!/bin/sh -e

. ../common-script.sh

gitpath="$HOME/.local/share/mybash"

installDepend() {
    if [ ! -f "/usr/share/bash-completion/bash_completion" ] || ! command_exists bash tar bat tree unzip fc-list git; then
        printf "%b\n" "${YELLOW}Installing Bash...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm bash bash-completion tar bat tree unzip fontconfig git fzf 
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add bash bash-completion tar bat tree unzip fontconfig git
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy bash bash-completion tar bat tree unzip fontconfig git
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y bash bash-completion tar bat tree unzip fontconfig git
                ;;
        esac
    fi
}

cloneMyBash() {
    # Check if the dir exists before attempting to clone into it.
    if [ -d "$gitpath" ]; then
        rm -rf "$gitpath"
    fi
    mkdir -p "$HOME/.local/share" # Only create the dir if it doesn't exist.
    cd "$HOME" && git clone https://github.com/ChrisTitusTech/mybash.git "$gitpath"
}

installFont() {
    # Check to see if the MesloLGS Nerd Font is installed (Change this to whatever font you would like)
    FONT_NAME="MesloLGS Nerd Font Mono"
    if fc-list :family | grep -iq "$FONT_NAME"; then
        printf "%b\n" "${GREEN}Font '$FONT_NAME' is installed.${RC}"
    else
        printf "%b\n" "${YELLOW}Installing font '$FONT_NAME'${RC}"
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
        printf "%b\n" "${GREEN}'$FONT_NAME' installed successfully.${RC}"
    fi
}

installStarshipAndFzf() {
    if command_exists starship; then
        printf "%b\n" "${GREEN}Starship already installed${RC}"
        return
    fi

    if [ "$PACKAGER" = "eopkg" ]; then
        "$ESCALATION_TOOL" "$PACKAGER" install -y starship || {
            printf "%b\n" "${RED}Failed to install starship with Solus!${RC}"
            exit 1
        }
    else
        curl -sSL https://starship.rs/install.sh | "$ESCALATION_TOOL" sh || {
            printf "%b\n" "${RED}Failed to install starship!${RC}"
            exit 1
        }
    fi

    if command_exists fzf; then
        printf "%b\n" "${GREEN}Fzf already installed${RC}"
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        "$ESCALATION_TOOL" ~/.fzf/install
    fi
}

installZoxide() {
    if command_exists zoxide; then
        printf "%b\n" "${GREEN}Zoxide already installed${RC}"
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

    mkdir -p "$HOME/.config"
    ln -svf "$gitpath/starship.toml" "$HOME/.config/starship.toml" || {
        printf "%b\n" "${RED}Failed to create symbolic link for starship.toml${RC}"
        exit 1
    }
    printf "%b\n" "${GREEN}Done! restart your shell to see the changes.${RC}"
}

checkEnv
checkEscalationTool
installDepend
cloneMyBash
installFont
installStarshipAndFzf
installZoxide
linkConfig
