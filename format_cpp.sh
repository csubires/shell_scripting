#!/usr/bin/env bash

# Code analysis script with multiple options
# Author: csubires
# Version: 1.1

set -euo pipefail
source utils.sh

# --- Configuration ---
readonly CLANG_FORMAT_CONFIG="$(dirname "$0")/config/.clang-format"
readonly SOURCE_CODE=("*.h" "*.hpp" "*.hxx" "*.c" "*.cpp" "*.cc" "*.cxx")
readonly CLANG_FORMAT_OPTS="--style=file:$CLANG_FORMAT_CONFIG"
readonly EXCLUDE_PATTERNS="*test* *migrations* *venv* *.env*"

helpPanel() {
    clear
    lg_prt "wtw" "\n" "C/C++ FORMAT" "\n"
    lg_prt "wobv" " Usage:" "./cpp_format.sh" "<Option>" "<Path>"
    lg_prt "bw" "\n\t-f, --format [FILE/DIR]" "\tFormat code with clang-format"
    lg_prt "bw" "\t-c, --check [FILE/DIR]" "\tAnalyze code with cppcheck"
    lg_prt "bw" "\t-i, --includes [DIR]" "\t\tExtract all unique includes"
    lg_prt "bw" "\t-t, --todos [DIR]" "\t\tShow all lines with TODO"
    lg_prt "bw" "\t-h, --help" "\t\t\tShow this help"
    lg_prt "wc" "\n Examples:"
    lg_prt "c" "\t$0 -f src/                   Format all files in src/"
    lg_prt "c" "\t$0 -c main.cpp               Analyze main.cpp with cppcheck"
    lg_prt "c" "\t$0 -i include/               Extract unique includes from include/"
    lg_prt "c" "\t$0 -t .                      Search TODOs in current directory"
    echo ""
    exit 0
}

# Function to find files by patterns
find_files() {
    local exclude_args=()
    local directory="$1"
    shift
    local patterns=("$@")
    local found_files=()
    for pattern in $EXCLUDE_PATTERNS; do
        exclude_args+=(-not -path "*/$pattern")
    done
    for pattern in "${patterns[@]}"; do
        while IFS= read -r -d $'\0' file; do
            found_files+=("$file")
        done < <(find "$directory" -type f -name "$pattern" "${exclude_args[@]}" -print0 2>/dev/null)
    done
    
    printf '%s\n' "${found_files[@]}"
}

# Function to format with clang-format
clang_format() {
    local target="$1"
    if [[ -d "$target" ]]; then
        local files=($(find_files "$target" "${SOURCE_CODE[@]}"))
        [[ ${#files[@]} -eq 0 ]] && { lg_prt "y" "No files found to format"; return; }
        lg_prt "g" "Formatting ${#files[@]} files..."
        for file in "${files[@]}"; do
            clang-format $CLANG_FORMAT_OPTS -i "$file"
        done  
    elif [[ -f "$target" ]]; then
        clang-format $CLANG_FORMAT_OPTS -i "$target"
    else
        lg_prt "r" "Error: $target is not a valid file or directory"
        exit 1
    fi
    lg_prt "g" "Formatting completed"
}

# Function to extract unique includes
extract_includes() {
    local directory="$1"
    [[ ! -d "$directory" ]] && { lg_prt "r" "Error: $directory is not a valid directory"; exit 1; }
    local files=($(find_files "$directory" "${SOURCE_CODE[@]}"))
    [[ ${#files[@]} -eq 0 ]] && { lg_prt "y" "No code files found"; return; }
    local includes=$(grep -h '^#include' "${files[@]}" 2>/dev/null | sort | uniq)
    [[ -z "$includes" ]] && lg_prt "y" "No includes found" || echo "$includes"
}

# Function to find TODOs (case insensitive)
find_todos() {
    local directory="$1"
    [[ ! -d "$directory" ]] && { lg_prt "r" "Error: $directory is not a valid directory"; exit 1; }
    local todos=$(find "$directory" -type f \( -name "*.cpp" -o -name "*.c" -o -name "*.h" -o -name "*.hpp" \) -exec \
                 egrep -n -i "TODO|TO-DO|TO DO|TO - DO" {} + 2>/dev/null || true)
    [[ -z "$todos" ]] && lg_prt "g" "No TODOs found!" || echo "$todos"
}

# Process arguments
[[ $# -eq 0 ]] && { helpPanel; exit 1; }

# Parse options
case $1 in
    -f|--format)    [[ $# -eq 2 ]] && clang_format "$2" || lg_prt "r" "Error: Option -f requires an argument";;
    -c|--check)     [[ $# -eq 2 ]] && cppcheck --enable=all "$2" || lg_prt "r" "Error: Option -c requires an argument";;
    -i|--includes)  [[ $# -eq 2 ]] && extract_includes "$2" || lg_prt "r" "Error: Option -i requires an argument";;
    -t|--todos)     [[ $# -eq 2 ]] && find_todos "$2" || find_todos ".";;
    -h|--help|*)    helpPanel;;
esac