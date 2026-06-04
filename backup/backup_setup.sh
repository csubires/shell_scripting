#!/usr/bin/env bash
# =============================================================================
#  backup_setup.sh — Encrypted Vault Backup System
# =============================================================================

# ── Utils ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/utils/color.sh"
. "$SCRIPT_DIR/utils/utils.sh"
. "$SCRIPT_DIR/utils/progressbar.sh"
. "$SCRIPT_DIR/utils/menu.sh"

# ── Config ────────────────────────────────────────────────────────────────────
NAME="backup_vault"
DESTINATION="/mnt/hgfs/BACKUPS"
CONTAINER_FILE="$NAME.img"
CONTAINER_PATH="$DESTINATION/$CONTAINER_FILE"
MAPPER_NAME="$NAME"
MOUNT_POINT="/tmp/vault_mount_${NAME}"
CONTAINER_SIZE="6G"

WORKSPACE="DEVELOPER"
WORKSPACES=("DEVELOPER" "SERVER" "CYBEROPS" "HOST" "SHARED")

COMPRESSION_LEVEL="9"
COMPRESSED_FILE="$NAME.7z"
COMPRESSED_PATH="$DESTINATION/$COMPRESSED_FILE"

# ── Config lists ──────────────────────────────────────────────────────────────
FOLDERS_LIST="$(pwd)/config/folders.list"
COMMAND_LIST="$(pwd)/config/command.list"
IGNORED_LIST="$(pwd)/config/ignore.list"

# ── render_menu wiring ────────────────────────────────────────────────────────
MENU_REQUIRE_ROOT=false
MENU_HELP_ON_EMPTY=true
MENU_SHOW_DONE=false
MENU_DEBUG=false
AUTO_CLEANUP=false

declare -A MENU_ROUTES=(
    [--create]="create_vault"
    [--open]="open_vault"
    [--close]="close_vault"
    [--sync]="sync_vault"
    [--commands]="run_commands"
    [--info]="show_info"
    [--compress]="compress_vault"
    [--decompress]="decompress_vault"
)

declare -A HELP_META=(
    [title]="Encrypted Vault Backup System"
    [script]="${BASH_SOURCE[0]}"
    [usage]="[FLAG]"
    [footer]="Vault: $CONTAINER_PATH  |  Workspace: $WORKSPACE"
)

HELP_OPTIONS=(
    "section|Vault Operations"
    "option|--create|Create a new encrypted LUKS vault"
    "option|--open|Open and mount the vault"
    "option|--close|Unmount and close the vault"
    "option|--sync|Sync sources from folders.list into the vault"
    "option|--commands|Run commands from command.list and save output"
    "blank|"
    "section|Maintenance"
    "option|--info|Show vault filesystem and workspace statistics"
    "option|--compress|Compress vault image with 7zip"
    "option|--decompress|Restore vault image from 7zip archive"
    "blank|"
    "section|Examples"
    "example|${BASH_SOURCE[0]} --sync|Full backup to active workspace"
    "example|${BASH_SOURCE[0]} --commands|Collect system info into vault"
    "example|${BASH_SOURCE[0]} --info|Show vault stats"
)

# =============================================================================
#  Internal helpers
# =============================================================================
_derive_key() {
    local SECRET="/home/$USER/.local/share/.secret"
    chk_file "$SECRET"
    local PHRASE
    PHRASE="$(head "$SECRET" -n 3 | tail -1)"
    echo -n "$(echo "$PHRASE" | base64 -d | sha256sum | head -c 32 | base64)"
}

_build_rsync_excludes() {
    [[ ! -f "$IGNORED_LIST" ]] && return
    while IFS= read -r pattern || [[ -n "$pattern" ]]; do
        pattern="$(echo "$pattern" | tr -d '\r' | xargs)"
        [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
        echo "--exclude=$pattern"
    done < "$IGNORED_LIST"
}

check_dependencies() {
    local missing=0
    for cmd in cryptsetup rsync 7z bc numfmt; do
        if ! command -v "$cmd" &>/dev/null; then
            lg_prt "r" "[✖] Missing command: $cmd"
            missing=1
        fi
    done
    if [[ $missing -eq 1 ]]; then
        lg_prt "y" "Install missing dependencies:"
        lg_prt "w" "  Debian/Ubuntu:" "sudo apt install cryptsetup rsync p7zip-full bc"
        lg_prt "w" "  RHEL/Fedora:  " "sudo dnf install cryptsetup rsync p7zip bc"
        exit 1
    fi
}

format_bytes() {
    numfmt --to=iec-i --suffix=B "$1" 2>/dev/null || lg_prt "w" "$1 bytes"
}

is_vault_open()    { [[ -e "/dev/mapper/$MAPPER_NAME" ]]; }
is_vault_mounted() { mountpoint -q "$MOUNT_POINT" 2>/dev/null; }

cleanup() {
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        lg_prt "y" "Unmounting vault..."
        sudo umount "$MOUNT_POINT" 2>/dev/null
    fi
    if [[ -e "/dev/mapper/$MAPPER_NAME" ]]; then
        lg_prt "y" "Closing LUKS device..."
        sudo cryptsetup luksClose "$MAPPER_NAME" 2>/dev/null
    fi
    rm -rf "$MOUNT_POINT" 2>/dev/null
}
trap '[ "$AUTO_CLEANUP" = true ] && cleanup' EXIT

_confirm() {
    local question="${1:-Continue?}"
    read -rp "$(echo -e "${PALETTE[y]}${question}${PALETTE[x]} [yes/no]: ")" _ANS
    [[ "$_ANS" == "yes" ]]
}

_section() {
    lg_prt "cn" " $*"
}

_kv() {
    # _kv COLOR "Label" "value"
    local color="$1" label="$2" value="$3"
    lg_prt "${color}w" "  ${label}:" "$value"
}

# =============================================================================
#  Vault operations
# =============================================================================
create_vault() {
    chk_root

    if [[ -f "$CONTAINER_PATH" ]]; then
        lg_prt "r" "[✖] Vault already exists:" "$CONTAINER_PATH"
        lg_prt "y" "    Use --open to access it, or delete it manually first."
        return 1
    fi

    mkdir -p "$DESTINATION"
    _section "Creating New Encrypted Vault"
    _kv "c" "Location  " "$CONTAINER_PATH"
    _kv "c" "Size      " "$CONTAINER_SIZE"
    _kv "c" "Workspaces" "${WORKSPACES[*]}"

    _confirm "Proceed with vault creation?" || { lg_prt "y" "Cancelled."; return 1; }

    local KEY; KEY="$(_derive_key)"

    pb_start 6 "Creating vault"

    pb_step "Creating sparse container ($CONTAINER_SIZE)..."
    truncate -s "$CONTAINER_SIZE" "$CONTAINER_PATH"

    pb_step "Initializing LUKS encryption..."
    echo -n "$KEY" | sudo cryptsetup luksFormat "$CONTAINER_PATH" - --batch-mode
    if [[ $? -ne 0 ]]; then
        pb_fail "LUKS initialization failed"
        rm -f "$CONTAINER_PATH"
        return 1
    fi

    pb_step "Opening LUKS device..."
    echo -n "$KEY" | sudo cryptsetup luksOpen "$CONTAINER_PATH" "$MAPPER_NAME" -

    pb_step "Formatting ext4 filesystem..."
    sudo mkfs.ext4 -L "EncryptedVault" "/dev/mapper/$MAPPER_NAME" -q

    pb_step "Mounting vault..."
    mkdir -p "$MOUNT_POINT"
    sudo mount "/dev/mapper/$MAPPER_NAME" "$MOUNT_POINT"

    pb_step "Creating workspace directories..."
    for ws in "${WORKSPACES[@]}"; do
        sudo mkdir -p "$MOUNT_POINT/$ws"
    done
    sudo bash -c "cat > '$MOUNT_POINT/README.txt'" << EOF
ENCRYPTED VAULT — WORKSPACE STRUCTURE
======================================
$(for ws in "${WORKSPACES[@]}"; do echo "  - $ws/"; done)
Active workspace : $WORKSPACE
Created          : $(date)
EOF
    sudo chmod -R 755 "$MOUNT_POINT"
    pb_done "Vault created"

    cleanup
    _section "Vault Created Successfully"
    _kv "g" "Location  " "$CONTAINER_PATH"
    _kv "g" "Size      " "$(du -h "$CONTAINER_PATH" | cut -f1)"
    _kv "g" "Encryption" "LUKS / AES-256"
    _kv "g" "Filesystem" "ext4"
}

# ─────────────────────────────────────────────────────────────────────────────
open_vault() {
	AUTO_CLEANUP=false
    chk_root
    chk_file "$CONTAINER_PATH"

    local KEY; KEY="$(_derive_key)"

    if ! is_vault_open; then
        lg_prt "c" "Opening LUKS device..."
        echo -n "$KEY" | sudo cryptsetup luksOpen "$CONTAINER_PATH" "$MAPPER_NAME" -
        if [[ $? -ne 0 ]]; then
            lg_prt "r" "[✖] Failed to open vault — check your secret file."
            return 1
        fi
    else
        lg_prt "y" "[!] Vault device already open."
    fi

    if ! is_vault_mounted; then
        mkdir -p "$MOUNT_POINT"
        lg_prt "c" "Mounting vault..."
        sudo mount "/dev/mapper/$MAPPER_NAME" "$MOUNT_POINT"
        if [[ $? -ne 0 ]]; then
            lg_prt "r" "[✖] Mount failed."
            sudo cryptsetup luksClose "$MAPPER_NAME"
            return 1
        fi
        sudo chmod 755 "$MOUNT_POINT"
    else
        lg_prt "y" "[!] Already mounted at:" "$MOUNT_POINT"
    fi

    lg_prt "g" "[✔] Vault mounted at:" "$MOUNT_POINT"
    lg_prt "cn" "Workspaces:"
    for ws in "${WORKSPACES[@]}"; do
        if [[ -d "$MOUNT_POINT/$ws" ]]; then
            local SIZE; SIZE=$(sudo du -sh "$MOUNT_POINT/$ws" 2>/dev/null | cut -f1)
            if [[ "$ws" == "$WORKSPACE" ]]; then
                lg_prt "gn" "  → $ws" "($SIZE)" "[ACTIVE]"
            else
                lg_prt "w" "  - $ws" "($SIZE)"
            fi
        fi
    done
}

# ─────────────────────────────────────────────────────────────────────────────
close_vault() {
    chk_root
    if ! is_vault_open && ! is_vault_mounted; then
        lg_prt "y" "[!] Vault is already closed."
        return 0
    fi
    lg_prt "c" "Closing vault..."
    cleanup
    lg_prt "g" "[✔] Vault closed."
}

# =============================================================================
#  Sync  (FOLDERS_LIST + IGNORED_LIST)
# =============================================================================
sync_vault() {
    chk_root
    chk_file "$FOLDERS_LIST"

    _section "Synchronizing Vault"
    _kv "c" "Workspace" "$WORKSPACE"
    _kv "c" "Sources  " "$FOLDERS_LIST"
    [[ -f "$IGNORED_LIST" ]] && _kv "c" "Ignored  " "$IGNORED_LIST"
    _kv "c" "Mode     " "Mirror (rsync --delete)"

    is_vault_mounted || open_vault || return 1

    local WORKSPACE_DIR="$MOUNT_POINT/$WORKSPACE"
    sudo mkdir -p "$WORKSPACE_DIR"

    local -a EXCLUDES
    while IFS= read -r exc; do EXCLUDES+=("$exc"); done < <(_build_rsync_excludes)

    local SIZE_BEFORE; SIZE_BEFORE=$(sudo du -sb "$WORKSPACE_DIR" 2>/dev/null | cut -f1)
    local TOTAL=0 SOURCES_FOUND=0 SOURCES_FAILED=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="$(echo "$line" | tr -d '\r' | xargs)"
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        (( TOTAL++ ))
    done < "$FOLDERS_LIST"

    pb_start "$TOTAL" "Syncing sources"

    while IFS= read -r SOURCE_PATH || [[ -n "$SOURCE_PATH" ]]; do
        SOURCE_PATH="$(echo "$SOURCE_PATH" | tr -d '\r' | xargs)"
        [[ -z "$SOURCE_PATH" || "$SOURCE_PATH" =~ ^# ]] && continue
        SOURCE_PATH="${SOURCE_PATH%/}"

        if [[ -d "$SOURCE_PATH" ]]; then
            pb_step "$(basename "$SOURCE_PATH")"
            sudo rsync -a --delete --info=progress2 \
                "${EXCLUDES[@]}" "$SOURCE_PATH/" "$WORKSPACE_DIR/$(basename "$SOURCE_PATH")/" \
                2>&1 | grep -v "^$"
            [[ ${PIPESTATUS[0]} -eq 0 ]] \
                && (( SOURCES_FOUND++ )) \
                || { (( SOURCES_FAILED++ )); lg_prt "r" "[✖] $SOURCE_PATH"; }

        elif [[ -f "$SOURCE_PATH" ]]; then
            pb_step "$(basename "$SOURCE_PATH")"
            local DEST_SUBDIR="$WORKSPACE_DIR/$(dirname "$SOURCE_PATH")"
            sudo mkdir -p "$DEST_SUBDIR"
            sudo rsync -a "${EXCLUDES[@]}" "$SOURCE_PATH" "$DEST_SUBDIR/"
            [[ $? -eq 0 ]] \
                && (( SOURCES_FOUND++ )) \
                || { (( SOURCES_FAILED++ )); lg_prt "r" "[✖] $SOURCE_PATH"; }

        else
            pb_step "NOT FOUND"
            lg_prt "r" "[✖] Not found:" "$SOURCE_PATH"
            (( SOURCES_FAILED++ ))
        fi
    done < "$FOLDERS_LIST"

    [[ $SOURCES_FOUND -eq 0 ]] && { pb_fail "No valid sources synced"; return 1; }
    pb_done "Sync complete"

    local SIZE_AFTER; SIZE_AFTER=$(sudo du -sb "$WORKSPACE_DIR" 2>/dev/null | cut -f1)
    local SIZE_DIFF=$(( SIZE_AFTER - SIZE_BEFORE ))

    _section "Sync Results"
    _kv "g" "Synced  " "$SOURCES_FOUND sources"
    [[ $SOURCES_FAILED -gt 0 ]] && _kv "r" "Failed  " "$SOURCES_FAILED sources"
    _kv "c" "Size now" "$(sudo du -sh "$WORKSPACE_DIR" | cut -f1)"
    if   [[ $SIZE_DIFF -gt 0 ]]; then _kv "g" "Change  " "+$(format_bytes $SIZE_DIFF)"
    elif [[ $SIZE_DIFF -lt 0 ]]; then _kv "y" "Change  " "-$(format_bytes $(( SIZE_DIFF * -1 )))"
    else                               _kv "w" "Change  " "none"
    fi
}

# =============================================================================
#  Run system commands  (COMMAND_LIST)
# =============================================================================
run_commands() {
    chk_root
    chk_file "$COMMAND_LIST"

    _section "Running System Commands"
    _kv "c" "List     " "$COMMAND_LIST"
    _kv "c" "Workspace" "$WORKSPACE"

    is_vault_mounted || open_vault || return 1

    local OUTPUT_DIR="$MOUNT_POINT/$WORKSPACE/sysinfo"
    sudo mkdir -p "$OUTPUT_DIR"

    local TIMESTAMP; TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
    local REPORT="$OUTPUT_DIR/sysinfo_${TIMESTAMP}.txt"

    local TOTAL=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="$(echo "$line" | tr -d '\r' | xargs)"
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        (( TOTAL++ ))
    done < "$COMMAND_LIST"

    {
        echo "# SYSTEM INFO REPORT"
        echo "# Generated : $(date)"
        echo "# Host      : $(hostname)"
        echo "# Workspace : $WORKSPACE"
    } | sudo tee "$REPORT" > /dev/null

    pb_start "$TOTAL" "Collecting system info"
    local CMD_OK=0 CMD_FAIL=0

    while IFS= read -r CMD_LINE || [[ -n "$CMD_LINE" ]]; do
        CMD_LINE="$(echo "$CMD_LINE" | tr -d '\r' | xargs)"
        [[ -z "$CMD_LINE" || "$CMD_LINE" =~ ^# ]] && continue

        pb_step "$CMD_LINE"
        {
            echo ""
            echo "# ── $CMD_LINE ──────────────────────────────"
            if eval "$CMD_LINE" 2>&1; then
                (( CMD_OK++ ))
            else
                echo "[exit code: $?]"
                (( CMD_FAIL++ ))
            fi
        } | sudo tee -a "$REPORT" > /dev/null

    done < "$COMMAND_LIST"

    [[ $CMD_OK -eq 0 ]] && { pb_fail "All commands failed"; return 1; }
    pb_done "Collection complete"

    _section "System Info Collected"
    _kv "g" "OK    " "$CMD_OK commands"
    [[ $CMD_FAIL -gt 0 ]] && _kv "r" "Failed" "$CMD_FAIL commands"
    _kv "c" "Report" "$REPORT"
}

# =============================================================================
#  Info / Stats
# =============================================================================
show_info() {
    chk_root
    chk_file "$CONTAINER_PATH"

    _section "Encrypted Vault Information"
    _kv "c" "Location  " "$CONTAINER_PATH"
    _kv "c" "File size " "$(du -h "$CONTAINER_PATH" | cut -f1)"
    _kv "c" "Max size  " "$CONTAINER_SIZE"
    _kv "c" "Encryption" "LUKS / AES-256"

    if [[ -f "$COMPRESSED_PATH" ]]; then
        lg_prt "cn" "  Compressed backup:"
        _kv "c" "  Location " "$COMPRESSED_PATH"
        _kv "c" "  Size     " "$(du -h "$COMPRESSED_PATH" | cut -f1)"
        _kv "c" "  Method   " "7zip (level $COMPRESSION_LEVEL)"
    fi

    local WAS_CLOSED=false
    if ! is_vault_mounted; then
        WAS_CLOSED=true
        lg_prt "y" "Opening vault to read details..."
        open_vault > /dev/null 2>&1 || { lg_prt "r" "[✖] Could not open vault."; return 1; }
    fi

    local FS_INFO; FS_INFO=$(sudo df -h "$MOUNT_POINT" | tail -1)
    lg_prt "cn" "  Filesystem:"
    _kv "c" "  Type     " "$(sudo df -T "$MOUNT_POINT" | tail -1 | awk '{print $2}')"
    _kv "c" "  Size     " "$(echo $FS_INFO | awk '{print $2}')"
    _kv "c" "  Used     " "$(echo $FS_INFO | awk '{print $3}')"
    _kv "c" "  Available" "$(echo $FS_INFO | awk '{print $4}')"
    _kv "c" "  Usage    " "$(echo $FS_INFO | awk '{print $5}')"

    lg_prt "cn" "  Workspaces:"
    local TOTAL_FILES=0 TOTAL_DIRS=0
    for ws in "${WORKSPACES[@]}"; do
        if [[ -d "$MOUNT_POINT/$ws" ]]; then
            local SIZE FILES DIRS
            SIZE=$(sudo du -sh "$MOUNT_POINT/$ws" 2>/dev/null | cut -f1)
            FILES=$(sudo find "$MOUNT_POINT/$ws" -type f 2>/dev/null | wc -l)
            DIRS=$(sudo find  "$MOUNT_POINT/$ws" -type d 2>/dev/null | wc -l)
            (( TOTAL_FILES += FILES, TOTAL_DIRS += DIRS ))
            if [[ "$ws" == "$WORKSPACE" ]]; then
                lg_prt "gn" "  → $ws" "[ACTIVE]" "$SIZE" "${FILES}f / ${DIRS}d"
            else
                lg_prt "w"  "  - $ws" "$SIZE" "${FILES}f / ${DIRS}d"
            fi
            local SYSINFO_DIR="$MOUNT_POINT/$ws/sysinfo"
            if [[ -d "$SYSINFO_DIR" ]]; then
                local RC; RC=$(sudo find "$SYSINFO_DIR" -name "sysinfo_*.txt" | wc -l)
                lg_prt "o" "    sysinfo reports:" "$RC"
            fi
        fi
    done

    lg_prt "cn" "  Totals:"
    _kv "w" "  Files      " "$TOTAL_FILES"
    _kv "w" "  Directories" "$TOTAL_DIRS"

    [[ "$WAS_CLOSED" == true ]] && close_vault > /dev/null 2>&1
}

# =============================================================================
#  Compress / Decompress
# =============================================================================
compress_vault() {
    chk_root
    chk_file "$CONTAINER_PATH"

    if is_vault_open || is_vault_mounted; then
        lg_prt "y" "Closing vault before compression..."
        close_vault
    fi

    _section "Compressing Vault"
    _kv "c" "Source     " "$CONTAINER_PATH"
    _kv "c" "Destination" "$COMPRESSED_PATH"
    _kv "c" "Level      " "$COMPRESSION_LEVEL (maximum)"

    local VAULT_SIZE; VAULT_SIZE=$(du -b "$CONTAINER_PATH" | cut -f1)
    _kv "c" "Vault size " "$(format_bytes $VAULT_SIZE)"
    lg_prt "y" "This may take several minutes..."

    [[ -f "$COMPRESSED_PATH" ]] && rm -f "$COMPRESSED_PATH"

    7z a -t7z -m0=lzma2 -mx="$COMPRESSION_LEVEL" -mfb=64 -md=32m -ms=on \
        "$COMPRESSED_PATH" "$CONTAINER_PATH" 2>&1 \
        | grep -E "^(Compressing|Everything is Ok|Error)"

    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        local COMPRESSED_SIZE; COMPRESSED_SIZE=$(du -b "$COMPRESSED_PATH" | cut -f1)
        local RATIO; RATIO=$(echo "scale=1; ($COMPRESSED_SIZE * 100) / $VAULT_SIZE" | bc)
        local SAVED=$(( VAULT_SIZE - COMPRESSED_SIZE ))
        _section "Compression Complete"
        _kv "g" "Original  " "$(format_bytes $VAULT_SIZE)"
        _kv "g" "Compressed" "$(format_bytes $COMPRESSED_SIZE)"
        _kv "g" "Ratio     " "${RATIO}%"
        _kv "g" "Saved     " "$(format_bytes $SAVED)"
    else
        lg_prt "r" "[✖] Compression failed!"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
decompress_vault() {
    chk_root
    chk_file "$COMPRESSED_PATH"

    if [[ -f "$CONTAINER_PATH" ]]; then
        lg_prt "y" "[!] Vault already exists at:" "$CONTAINER_PATH"
        _confirm "Overwrite?" || { lg_prt "y" "Cancelled."; return 1; }
        rm -f "$CONTAINER_PATH"
    fi

    _section "Decompressing Vault"
    _kv "c" "Source     " "$COMPRESSED_PATH"
    _kv "c" "Destination" "$DESTINATION"

    7z x "$COMPRESSED_PATH" -o"$DESTINATION" -y
    if [[ $? -eq 0 ]]; then
        lg_prt "g" "[✔] Decompression complete. Vault restored to:" "$CONTAINER_PATH"
    else
        lg_prt "r" "[✖] Decompression failed!"
        return 1
    fi
}

# =============================================================================
#  Entry point
# =============================================================================
check_dependencies
render_menu "$@"
