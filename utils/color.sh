#!/usr/bin/env bash

# Colors
declare -A PALETTE=(
    [w]="\e[97m"            # White
    [r]="\e[91m"            # Red
    [g]="\e[92m"            # Green
    [y]="\e[93m"            # Yellow
    [b]="\e[94m"            # Blue
    [v]="\e[95m"            # Violet
    [c]="\e[96m"            # Cyan
    [o]="\e[33m"            # Orange
    [n]="\e[1m"             # Bold
    [u]="\e[04m"            # Underline
    [t]="\t\e[1;42;97m"     # Title (green background, white text)
    [x]="\e[0m"             # Reset (to clear formatting)
)

function ctrl_c() {
    lg_prt "y" "[▲] Exiting due to interrupt"
    exit 1
}

# Execute on Ctrl+C
trap ctrl_c INT

function lg_prt() {
    if [[ $# -lt 2 ]]; then
        echo -e "${PALETTE[r]}Error (lg_prt): Insufficient arguments${PALETTE[x]}"
        return 1
    fi

    local colors="$1"
    local messages=("${@:2}")
    local color_length=${#colors}
    local message_count=${#messages[@]}

    if ((color_length < message_count)); then
        colors+="${colors: -1}$(printf "%*s" $((message_count - color_length)) "")"
    fi

    for ((i = 0; i < message_count; i++)); do
        echo -ne "${PALETTE[${colors:$i:1}]}${messages[$i]}${PALETTE[x]} "
    done
    echo
}
