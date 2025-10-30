#!/bin/sh -e

# YubiKey-PAM Configuration
# Adds YubiKey touch-based authentication to sudo via pam_u2f with password fallback.

. ../common-script.sh
checkEnv

SUDO_PAM="/etc/pam.d/sudo"

# Determine the actual user being configured (supports running via sudo)
TARGET_USER=${SUDO_USER:-$USER}
TARGET_HOME=$(eval echo ~"$TARGET_USER")
U2F_DIR="$TARGET_HOME/.config/Yubico"
U2F_KEYS_FILE="$U2F_DIR/u2f_keys"
BACKUP_PATH="$TARGET_HOME/pam_u2f_backup.tgz"

printf "%b\n" "${CYAN}Starting YubiKey PAM setup for user: ${TARGET_USER}${RC}"

# Allow selecting additional PAM targets to enable pam_u2f, beyond sudo
printf "%b\n" "${YELLOW}Select where to enable pam_u2f (comma-separated).${RC}"
printf "%b\n" "  1) sudo (/etc/pam.d/sudo)"
printf "%b\n" "  2) system-auth (/etc/pam.d/system-auth) [affects many services]"
printf "%b" "Choice [default: 1]: "
read -r _sel
if [ -z "$_sel" ]; then _sel="1"; fi

# Build target list based on explicit selection only (no implicit sudo)
TARGET_PAM_FILES=""

add_target_if_exists() {
    _file=$1
    _name=$2
    if [ -f "$_file" ]; then
        case " $TARGET_PAM_FILES " in
            *" $_file "*) : ;; # already included
            *) TARGET_PAM_FILES="$TARGET_PAM_FILES $_file" ;;
        esac
    else
        printf "%b\n" "${YELLOW}Überspringe ${_name}: Datei nicht gefunden ($_file).${RC}"
    fi
}

# Parse comma-separated selection
for sel in $(printf "%s" "$_sel" | tr ',' ' '); do
    case "$sel" in
        1) add_target_if_exists "$SUDO_PAM" "sudo" ;;
        2)
            printf "%b" "${YELLOW}Warning: system-auth affects many services. Continue? [y/N] ${RC}"
            read -r _ok
            case "$_ok" in
                y|Y|yes|YES) add_target_if_exists "/etc/pam.d/system-auth" "system-auth" ;;
                *) printf "%b\n" "${YELLOW}system-auth not selected.${RC}" ;;
            esac
            ;;
        *) printf "%b\n" "${YELLOW}Unknown choice: ${sel} (ignored).${RC}" ;;
    esac
done

if [ -z "$TARGET_PAM_FILES" ]; then
    printf "%b\n" "${RED}No PAM targets selected. Aborting without making changes.${RC}"
    exit 1
fi

sudo_selected=false
other_targets=false
for pamf in $TARGET_PAM_FILES; do
    if [ "$pamf" = "$SUDO_PAM" ]; then
        sudo_selected=true
    else
        other_targets=true
    fi
done

if [ "$sudo_selected" = true ] && [ "$other_targets" = false ]; then
    if "$ESCALATION_TOOL" sh -c "grep -Eq '^[[:space:]]*auth[[:space:]]+.*pam_u2f\\.so' '$SUDO_PAM'"; then
        printf "%b\n" "${GREEN}pam_u2f already configured in ${SUDO_PAM} – no changes required.${RC}"
        exit 0
    fi
fi

printf "%b\n" "${CYAN}PAM targets: ${TARGET_PAM_FILES}${RC}"

# Backup selected PAM configuration files (+ optional u2f mappings path if present)
FILES_TO_BACKUP=""
for f in $TARGET_PAM_FILES; do
    case "$f" in
        /etc/pam.d/*) FILES_TO_BACKUP="$FILES_TO_BACKUP ${f#/}" ;;
    esac
done
if "$ESCALATION_TOOL" test -e /etc/u2f_mappings; then
    FILES_TO_BACKUP="$FILES_TO_BACKUP etc/u2f_mappings"
fi
FILES_TO_BACKUP=$(printf "%s" "$FILES_TO_BACKUP" | sed 's/^ *//')
if [ -n "$FILES_TO_BACKUP" ]; then
    "$ESCALATION_TOOL" sh -c "tar -C / -czf '$BACKUP_PATH' $FILES_TO_BACKUP"
    printf "%b\n" "${GREEN}Backup created at ${BACKUP_PATH}${RC}"
else
    printf "%b\n" "${YELLOW}No PAM files found to back up.${RC}"
fi

# Function to ensure pam_u2f line exists in a PAM file in the right position
ensure_pam_u2f_in_file() {
    _pam_file=$1
    NEWLINE='auth sufficient pam_u2f.so cue'
    # First, remove any existing non-comment pam_u2f auth lines to avoid duplicates
        EXISTING_COUNT=$("$ESCALATION_TOOL" grep -cE '^[[:space:]]*auth[[:space:]]+.*pam_u2f\\.so' "$_pam_file" 2>/dev/null || true)
        if [ "${EXISTING_COUNT:-0}" -gt 0 ]; then
            if [ "$EXISTING_COUNT" -gt 1 ]; then
                "$ESCALATION_TOOL" sh -c "awk '
                    BEGIN { pattern = \"^[[:space:]]*auth[[:space:]]+.*pam_u2f\\.so\"; seen = 0 }
                    {
                        if (
                            \$0 ~ pattern
                        ) {
                            if (seen) next;
                            seen = 1;
                        }
                        print
                    }
                ' '$_pam_file' > '$_pam_file.tmp' && mv '$_pam_file.tmp' '$_pam_file'"
                printf "%b\n" "${CYAN}pam_u2f already present: $_pam_file (deduplicated existing entries)${RC}"
            else
                printf "%b\n" "${CYAN}pam_u2f already present: $_pam_file (skipping insert)${RC}"
            fi
            return 0
        fi
    printf "%b\n" "${YELLOW}Updating PAM: $_pam_file${RC}"
    if "$ESCALATION_TOOL" sh -c "awk -v n=\"$NEWLINE\" '
        BEGIN{inserted=0;}
        {
            if (!inserted && \$0 ~ /^[[:space:]]*auth[[:space:]]+(include|substack)[[:space:]]+(common-auth|system-auth)/) {
                print n; print; inserted=1; next
            }
            if (!inserted && \$0 ~ /^[[:space:]]*auth[[:space:]]+/) {
                print n; print; inserted=1; next
            }
            print
        }
        END{
            if (!inserted) print n
        }' '$_pam_file' > '$_pam_file.tmp' && mv '$_pam_file.tmp' '$_pam_file'"; then
        printf "%b\n" "${GREEN}PAM configured: $_pam_file${RC}"
        return 0
    else
        printf "%b\n" "${RED}Automatic insertion failed. Falling back to appending at end of file.${RC}"
        "$ESCALATION_TOOL" sh -c "printf '%s\n' '$NEWLINE' >> '$_pam_file'"
        printf "%b\n" "${YELLOW}Appended line at the end of $_pam_file. Verify ordering if needed.${RC}"
    fi
}

# Apply pam_u2f insertion to all chosen PAM files
for pamf in $TARGET_PAM_FILES; do
    ensure_pam_u2f_in_file "$pamf"
done

# Enroll YubiKey for pam_u2f (robust: check exit status and output)
printf "%b\n" "${YELLOW}Enrolling YubiKey for pam_u2f…${RC}"

if ! command_exists pamu2fcfg; then
    printf "%b\n" "${RED}pamu2fcfg not found. Install the enrollment tool first:${RC}"
    printf "%b\n" "  - Arch/Manjaro: pam-u2f"
    printf "%b\n" "  - Debian/Ubuntu: libpam-u2f"
    printf "%b\n" "  - Fedora/openSUSE/Void: pam_u2f"
    exit 1
fi

"$ESCALATION_TOOL" true >/dev/null 2>&1 || :
# Create config directory owned by the target user, with secure permissions
"$ESCALATION_TOOL" install -d -m 700 -o "$TARGET_USER" -g "$TARGET_USER" "$U2F_DIR"

# Backup existing keys file if present
if [ -f "$U2F_KEYS_FILE" ]; then
    "$ESCALATION_TOOL" cp -f "$U2F_KEYS_FILE" "$U2F_KEYS_FILE.bak"
    "$ESCALATION_TOOL" chown "$TARGET_USER":"$TARGET_USER" "$U2F_KEYS_FILE.bak" 2>/dev/null || true
    printf "%b\n" "${YELLOW}Existing U2F file backed up: ${U2F_KEYS_FILE}.bak${RC}"
fi

# Helper to run a command as TARGET_USER using available tool (sudo/doas/su)
run_as_target_user() {
    _cmd=$1
    if command_exists sudo; then
        sudo -u "$TARGET_USER" sh -c "$_cmd"
    elif command_exists doas; then
        doas -u "$TARGET_USER" sh -c "$_cmd"
    else
        su - "$TARGET_USER" -c "$_cmd"
    fi
}

TMP_U2F="/tmp/u2f_${TARGET_USER}_$$.map"
if run_as_target_user "umask 077; pamu2fcfg > '$TMP_U2F'"; then
    if [ -s "$TMP_U2F" ] && grep -q ':' "$TMP_U2F"; then
        # Only replace on success with non-empty mapping
        if [ -f "$U2F_KEYS_FILE" ]; then
            "$ESCALATION_TOOL" cp -f "$U2F_KEYS_FILE" "$U2F_KEYS_FILE.bak"
            "$ESCALATION_TOOL" chown "$TARGET_USER":"$TARGET_USER" "$U2F_KEYS_FILE.bak" 2>/dev/null || true
        fi
        "$ESCALATION_TOOL" install -m 600 -o "$TARGET_USER" -g "$TARGET_USER" "$TMP_U2F" "$U2F_KEYS_FILE"
        printf "%b\n" "${GREEN}U2F key mapping created: ${U2F_KEYS_FILE}${RC}"
    else
        printf "%b\n" "${RED}Registration timed out or returned no data. Existing mapping left unchanged.${RC}"
        rm -f "$TMP_U2F" 2>/dev/null || true
        exit 1
    fi
else
    printf "%b\n" "${RED}Registration failed. Ensure a YubiKey is connected and try again.${RC}"
    rm -f "$TMP_U2F" 2>/dev/null || true
    exit 1
fi
rm -f "$TMP_U2F" 2>/dev/null || true

# Testing and rollback guidance
printf "%b\n" "${YELLOW}Test: open a new terminal, run 'sudo -k; sudo true' and touch your YubiKey when prompted.${RC}"
printf "%b\n" "${YELLOW}Rollback: restore backup with${RC}"
printf "%b\n" "  ${CYAN}$ESCALATION_TOOL tar -C / -xzf '$BACKUP_PATH'${RC}"

printf "%b\n" "${GREEN}YubiKey-PAM setup complete.${RC}"