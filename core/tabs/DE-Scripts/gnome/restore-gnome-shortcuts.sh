#!/usr/bin/env bash
# Restore GNOME Keyboard Shortcuts
# ------------------------------------------------------------------------------
set -Eeuo pipefail

# Logging helpers with color fallbacks
: "${INFO:=[INFO]}"
: "${WARN:=[WARN]}"
: "${OK:=[OK]}"
: "${YELLOW:=}"
: "${GREEN:=}"
: "${RED:=}"
: "${NC:=}"

log_info() { echo "${INFO} ${YELLOW}$*${NC}"; }
log_ok()   { echo "${OK} ${GREEN}$*${NC}"; }
log_warn() { echo "${WARN} ${RED}$*${NC}"; }

# Flags
DRY_RUN=false
BACKUP=true
while [[ -n ${1-} ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        --no-backup) BACKUP=false ;;
        -h|--help)
            cat <<EOF
Usage: $(basename "$0") [--dry-run] [--no-backup]
    --dry-run   Print intended gsettings changes without applying them
    --no-backup Skip writing backup files before changes
EOF
            exit 0
            ;;
        *) log_warn "Unknown option: $1"; exit 2 ;;
    esac
    shift || true
done

# Preflight checks
if ! command -v gsettings >/dev/null 2>&1; then
    log_warn "gsettings not found. This script requires GNOME gsettings."
    exit 1
fi
if ! gsettings list-schemas | grep -q '^org.gnome.settings-daemon.plugins.media-keys$'; then
    log_warn "GNOME schema org.gnome.settings-daemon.plugins.media-keys not found."
    exit 1
fi

log_info "Restoring GNOME keyboard shortcuts..."

# Define the list of custom keybinding paths
CUSTOM_KEYBINDINGS=(
        '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/'
        '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/'
        '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/'
        '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/'
        '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/'
        '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/'
        '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/'
        '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/'
        '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9/'
)

# Build a valid GVariant array string like: ['path0/', 'path1/']
kb_list="["
for p in "${CUSTOM_KEYBINDINGS[@]}"; do
    kb_list+="'${p}', "
done
kb_list="${kb_list%, }]"

# Optionally backup current config
if [[ ${BACKUP} == true ]]; then
    mkdir -p output
    gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
        > output/gnome-custom-keybindings.before.txt || true
    if command -v dconf >/dev/null 2>&1; then
        dconf dump /org/gnome/settings-daemon/plugins/media-keys/ \
            > output/gnome-media-keys.before.dconf || true
    fi
fi

if [[ ${DRY_RUN} == true ]]; then
    log_info "DRY-RUN: Would set custom-keybindings to: ${kb_list}"
else
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${kb_list}"
fi

# Define shortcuts data
declare -A SHORTCUTS
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']='name:Terminal|command:guake|binding:<Super>x'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']='name:Text Editor|command:flatpak run org.gnome.gitlab.cheywood.Buffer/x86_64/stable|binding:<Super>t'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']='name:VS Code|command:code|binding:<Super>c'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/']='name:Yubikey Authenticator|command:yubico-authenticator|binding:<Super>y'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/']='name:Files|command:nautilus --new-window|binding:<Super>f'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/']='name:Ghostty|command:ghostty|binding:<Alt><Super>x'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/']='name:Signal|command:signal-desktop|binding:<Super>m'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/']='name:WhatsApp|command:flatpak run com.rtosta.zapzap|binding:<Alt><Super>m'
SHORTCUTS['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9/']='name:Hardware Info|command:hardinfo2|binding:<Super>i'

# Apply each shortcut in the declared order for determinism
for path in "${CUSTOM_KEYBINDINGS[@]}"; do
    if [[ -z "${SHORTCUTS[${path}]+_}" ]]; then
        log_warn "No shortcut data defined for ${path} — skipping."
        continue
    fi

    IFS='|' read -r name_part command_part binding_part <<< "${SHORTCUTS[${path}]}"
    name_value="${name_part#*:}"
    command_value="${command_part#*:}"
    binding_value="${binding_part#*:}"

    # Basic validation: warn if the referenced command binary seems missing
    cmd_bin="${command_value%% *}"
    if ! command -v "${cmd_bin}" >/dev/null 2>&1; then
        log_warn "Command not found in PATH: ${cmd_bin} (for ${path})"
    fi

    if [[ ${DRY_RUN} == true ]]; then
        log_info "DRY-RUN: Would set ${path} -> name='${name_value}', command='${command_value}', binding='${binding_value}'"
    else
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${path}" name "${name_value}"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${path}" command "${command_value}"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"${path}" binding "${binding_value}"
    fi
done

log_ok "GNOME keyboard shortcuts restored."