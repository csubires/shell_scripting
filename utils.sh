#!/bin/bash

# Colors
declare -A PALETTE=(
    [w]="\e[97m"      # White
    [r]="\e[91m"      # Red
    [g]="\e[92m"      # Green
    [y]="\e[93m"      # Yellow
    [b]="\e[94m"      # Blue
    [v]="\e[95m"      # Violet
    [c]="\e[96m"      # Cyan
    [o]="\e[33m"      # Orange
    [n]="\e[1m"       # Bold
    [u]="\e[04m"      # Underline
    [t]="\t\e[1;42;97m" # Title (green background, white text)
    [x]="\e[0m"       # Reset (to clear formatting)
)

function ctrl_c() {
    lg_prt "y" "[▲] Exiting due to interrupt"
    exit 1
}

# Execute on Ctrl+C
trap ctrl_c INT

function lg_prt() {
    # Verify there's at least a color and a message
    if [[ $# -lt 2 ]]; then
        echo -e "${PALETTE[r]}Error (lg_prt): Insufficient arguments${PALETTE[x]}"
        return 1
    fi

    local colors="$1"
    local messages=("${@:2}")
    local color_length=${#colors}
    local message_count=${#messages[@]}

    # If fewer colors than messages, repeat the last color
    if ((color_length < message_count)); then
        colors+="${colors: -1}$(printf "%*s" $((message_count - color_length)) "")"
    fi

    # Print each message with its corresponding color
    for ((i = 0; i < message_count; i++)); do
        echo -ne "${PALETTE[${colors:$i:1}]}${messages[$i]}${PALETTE[x]} "
    done
    echo  # Line break at the end
}

# Function to check if a path (file or directory) exists
function chk_path() {
    local path="$1"

    # Convert relative path to absolute (if needed)
    if ! absolute_path=$(realpath -e "$path" 2>/dev/null); then
        lg_prt "r" "Error (chk_path): Path \"$path\" does not exist."
        return 1  # Path doesn't exist
    fi

    # Verify path exists (redundant check since realpath already did this)
    if [[ -e "$absolute_path" ]]; then
        return 0  # Path exists
    else
        lg_prt "r" "Error (chk_path): Path \"$absolute_path\" does not exist."
        return 1  # Path doesn't exist
    fi
}

function test_utils() {
    # Test all colors
    for color in "${!PALETTE[@]}"; do
        [[ "$color" != "x" ]] && lg_prt "$color" "Color: $color"
    done

    # Test error cases
    lg_prt "r" "Error: Sample error message"
    lg_prt "y" "Warning: Sample warning"

    # Test path checking
    local test_paths=(
        "/home/user/Documents/Scripts/utils.sh"
        "./utils.sh"
        "./nonexistent.sh"
    )

    for path in "${test_paths[@]}"; do
        if chk_path "$path"; then
            lg_prt "g" "Path exists:" "$path"
        else
            lg_prt "r" "Path not found:" "$path"
        fi
    done
}

# test_utils
