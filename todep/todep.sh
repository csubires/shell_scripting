#!/usr/bin/env bash
# ============================================
# Script: todep.sh
# Description: Combine source files by mode, removing comments and empty lines.
# Adds directory tree and file headers to the output.
# Author: [Your Name]
# ============================================

# open /web/index.html

set -e

# --- Configuration ---
FILTER_DIR="$(dirname "$0")/filters"
OUTPUT_DIR="/tmp"
OUTPUT_FILE=""
MODE="all"

# --- Carpetas a ignorar ---
IGNORE_DIRS=(
    "node_modules"
    ".git"
    "dist"
    "build"
    "__pycache__"
    ".venv"
    "venv"
    "env"
    ".idea"
    ".vscode"
    "vendor"
    "target"
)

# --- Extension groups ---
declare -A EXT_GROUPS
EXT_GROUPS["web"]="html js ts css scss sass json"
EXT_GROUPS["python"]="py conf cnf"
EXT_GROUPS["cpp"]="c h hpp cpp Makefile"
EXT_GROUPS["server"]="Dockerfile docker-compose Containerfile Container-compose podman yml env conf cnf json Makefile base sh hcl"
EXT_GROUPS["bash"]="sh zsh awk sed list"
EXT_GROUPS["grafa"]="Dockerfile docker-compose rules conf yml json"

# --- Functions ---
function usage() {
    echo "Usage: $0 [mode] [files or paths]"
    echo "Modes:"
    echo "  all      - All recognized file extensions (default)"
    echo "  web      - HTML, JS, CSS, etc."
    echo "  python   - Python-related files"
    echo "  cpp      - C/C++ source files"
    echo "  server   - Docker/Server related files"
    echo "  bash     - Bash scripting"
    echo "  list     - Read file paths from a .list file"
	echo "  list     - Open HTML prompt IA"
    exit 1
}

function check_filters() {
    [[ -f "$FILTER_DIR/clean_comments.awk" && -f "$FILTER_DIR/remove_empty_lines.sed" ]] || {
        echo "[ERROR] Missing filters in $FILTER_DIR"
        exit 1
    }
}

function check_file_exists() {
    if [[ ! -e "$1" ]]; then
        echo "[ERROR] File or path not found: $1"
        exit 1
    fi
}

# Nueva función para construir el parámetro -prune de find
function build_prune_expression() {
    local prune_expr=""
    local first=true

    for dir in "${IGNORE_DIRS[@]}"; do
        if [[ "$first" == true ]]; then
            prune_expr="-path '*/$dir' -prune"
            first=false
        else
            prune_expr="$prune_expr -o -path '*/$dir' -prune"
        fi
    done

    echo "$prune_expr"
}

function get_file_list() {
    local mode="$1"; shift
    local files=()
    local prune_expr
    prune_expr=$(build_prune_expression)

    if [[ "$mode" == "list" ]]; then
        local list_file="$1"
        check_file_exists "$list_file"
        mapfile -t files < "$list_file"
    else
        for item in "$@"; do
            check_file_exists "$item"
            if [[ -d "$item" ]]; then
                if [[ "$mode" == "all" ]]; then
                    # Buscar todos los archivos, ignorando las carpetas especificadas
                    files+=($(eval "find '$item' $prune_expr -o -type f -print" 2>/dev/null))
                else
                    # Construir patrón de búsqueda para find
                    local find_patterns=()
                    for ext in ${EXT_GROUPS[$mode]}; do
                        if [[ "$ext" == *"."* ]] || [[ ${#ext} -le 5 ]]; then
                            # Es una extensión (sin punto o con pocos caracteres)
                            find_patterns+=("-name '*.$ext'")
                        else
                            # Es un nombre de archivo completo (como Dockerfile, Makefile)
                            find_patterns+=("-name '$ext'")
                        fi
                    done

                    # Combinar todos los patrones con -o
                    local find_expr=""
                    local first=true
                    for pattern in "${find_patterns[@]}"; do
                        if [[ "$first" == true ]]; then
                            find_expr="$pattern"
                            first=false
                        else
                            find_expr="$find_expr -o $pattern"
                        fi
                    done

                    # Ejecutar find con los patrones combinados
                    if [[ -n "$find_expr" ]]; then
                        files+=($(eval "find '$item' $prune_expr -o -type f \\( $find_expr \\) -print" 2>/dev/null))
                    fi
                fi
            else
                files+=("$item")
            fi
        done
    fi
    echo "${files[@]}"
}

function generate_tree_section() {
    local paths=("$@")
    echo "[INFO] Generating directory tree..." >&2
    echo "========== DIRECTORY TREE =========="

    # Construir patrón para tree
    local tree_ignore=""
    for dir in "${IGNORE_DIRS[@]}"; do
        if [[ -z "$tree_ignore" ]]; then
            tree_ignore="$dir"
        else
            tree_ignore="$tree_ignore|$dir"
        fi
    done

    for path in "${paths[@]}"; do
        if [[ -d "$path" ]]; then
            echo "[DIR] $path"
            if command -v tree >/dev/null 2>&1; then
                tree -a -I "$tree_ignore" "$path"
            else
                # Generar árbol manualmente excluyendo carpetas ignoradas
                local prune_expr
                prune_expr=$(build_prune_expression)
                eval "find '$path' $prune_expr -o -print" | awk '
                    BEGIN { prev_depth = 0 }
                    {
                        gsub(/^\.\//, "", $0)
                        split($0, parts, "/")
                        depth = length(parts)
                        indent = ""
                        for (i=1; i<depth; i++) indent = indent "│   "
                        if (depth > prev_depth) {
                            print indent "├── " parts[depth]
                        } else {
                            print indent "└── " parts[depth]
                        }
                        prev_depth = depth
                    }'
            fi
        else
            echo "├── $path"
        fi
    done
}

function process_files() {
    local mode="$1"; shift
    local files=("$@")

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "[WARN] Total files found: 0"
        echo "[INFO] No report generated."
        exit 0
    fi

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    OUTPUT_FILE="${OUTPUT_DIR}/source_${mode}.txt"

    # --- Select AWK filter based on mode ---
    case "$mode" in
        cpp)
            AWK_FILTER="$FILTER_DIR/clean_comments_cpp.awk"
            ;;
        python)
            AWK_FILTER="$FILTER_DIR/clean_comments_python.awk"
            ;;
        web)
            AWK_FILTER="$FILTER_DIR/clean_comments_web.awk"
            ;;
        bash)
            AWK_FILTER="$FILTER_DIR/clean_comments_bash.awk"
            ;;
		prompt)
			open "/home/user/Documents/Scripts/todep/web/index.html"
			;;
        *)
            AWK_FILTER="$FILTER_DIR/clean_comments.awk"
            ;;
    esac

    if [[ ! -f "$AWK_FILTER" ]]; then
        echo "[ERROR] AWK filter not found for mode '$mode': $AWK_FILTER"
        exit 1
    fi

    echo "[INFO] Writing output to: $OUTPUT_FILE"
    : > "$OUTPUT_FILE"

    {
        echo "========== REPORT GENERATED =========="
        echo "Mode: $mode"
        echo "Date: $timestamp"
        echo "Ignored directories: ${IGNORE_DIRS[*]}"
        generate_tree_section "$@"
        echo "========== FILE CONTENTS =========="
    } >> "$OUTPUT_FILE"

    for f in "${files[@]}"; do
        echo "[INFO] Processing $f"
        {
            echo "----------------------------------------"
            echo ">>> FILE: $(realpath "$f")"
            echo "----------------------------------------"
            awk -f "$AWK_FILTER" "$f" | sed -f "$FILTER_DIR/remove_empty_lines.sed"
        } >> "$OUTPUT_FILE"
    done

    echo "[INFO] All done. Output saved to: $OUTPUT_FILE"
    echo "📦 Tamaño del archivo $OUTPUT_FILE: $(stat -c %s "$OUTPUT_FILE" | numfmt --to=iec)"
}


# --- Main ---
[[ $# -lt 1 ]] && usage
MODE="$1"; shift
[[ $# -lt 1 ]] && usage

check_filters
FILES_TO_PROCESS=($(get_file_list "$MODE" "$@"))

echo "[INFO] Mode: $MODE"
echo "[INFO] Ignored directories: ${IGNORE_DIRS[*]}"
echo "[INFO] Total files found: ${#FILES_TO_PROCESS[@]}"

process_files "$MODE" "${FILES_TO_PROCESS[@]}"
