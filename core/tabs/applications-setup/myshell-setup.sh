#!/bin/sh -e

. ../common-script.sh

# Resolve TL40-Dots repository path locally (no network clone)
# Prefer an explicit env var, then search this repo tree, then common locations.
gitpath=""
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd -P)

resolveDotfilesPath() {
    # 1) DOTFILES_REPO_PATH environment variable
    if [ -n "${DOTFILES_REPO_PATH:-}" ] && [ -f "$DOTFILES_REPO_PATH/config/.bashrc" ]; then
        gitpath="$DOTFILES_REPO_PATH"
        return 0
    fi

    # 2) Known subfolders inside current project (if TL40-Dots is vendored here)
    for candidate in \
        "$REPO_ROOT/TL40-Dots" \
        "$REPO_ROOT/external/TL40-Dots" \
        "$REPO_ROOT/vendor/TL40-Dots" \
        "$REPO_ROOT/dotfiles"; do
        if [ -f "$candidate/config/.bashrc" ]; then
            gitpath="$candidate"
            return 0
        fi
    done

    # 3) Try to discover by searching for config/.bashrc within the repo (bounded depth)
    found=$(find "$REPO_ROOT" -maxdepth 5 -type f -path "*/config/.bashrc" 2>/dev/null | head -n1 || true)
    if [ -n "$found" ]; then
        gitpath=$(cd "$(dirname "$found")/.." && pwd -P)
        return 0
    fi

    # 4) Common user locations if repo was restored previously
    for candidate in \
        "$HOME/.dotfiles" \
        "$HOME/Projects/TL40-Dots"; do
        if [ -f "$candidate/config/.bashrc" ]; then
            gitpath="$candidate"
            return 0
        fi
    done

    # Not found – instruct user to run the Dotfiles Restore task
    printf "%b\n" "${RED}TL40-Dots repository not found locally.${RC}"
    printf "%b\n" "${YELLOW}Hint:${RC} Run the Dotfiles → 'TL40 Dotfiles Restore' first, or set DOTFILES_REPO_PATH to your local TL40-Dots checkout."
    exit 1
}

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

resolveDotfilesPath

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
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        # Install for current user without modifying shell rc automatically
        "$HOME/.fzf/install" --key-bindings --completion --no-update-rc
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
    if [ -L "$HOME/.bashrc" ] && [ "$(readlink "$HOME/.bashrc")" = "$gitpath/config/.bashrc" ]; then
        printf "%b\n" "${GREEN}.bashrc already linked to TL40-Dots${RC}"
    else
        ln -svf "$gitpath/config/.bashrc" "$HOME/.bashrc" || {
            printf "%b\n" "${RED}Failed to create symbolic link for .bashrc${RC}"
            exit 1
        }
    fi

    mkdir -p "$HOME/.config"
    if [ -f "$gitpath/config/starship.toml" ]; then
        ln -svf "$gitpath/config/starship.toml" "$HOME/.config/starship.toml" || {
            printf "%b\n" "${RED}Failed to create symbolic link for starship.toml${RC}"
            exit 1
        }
    fi

    # Optionally link fish config if present in the dotfiles repo
    if [ -f "$gitpath/config/fish/config.fish" ]; then
        mkdir -p "$HOME/.config/fish"
        ln -svf "$gitpath/config/fish/config.fish" "$HOME/.config/fish/config.fish" || {
            printf "%b\n" "${RED}Failed to create symbolic link for fish config${RC}"
            exit 1
        }
    fi
    printf "%b\n" "${GREEN}Done! restart your shell to see the changes.${RC}"
}

checkEnv
checkEscalationTool
installDepend
installFont
installStarshipAndFzf
installZoxide
linkConfig
