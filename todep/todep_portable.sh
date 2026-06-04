#!/usr/bin/env bash

# open /web/index.html

DIRS=()
OUT_LIST="/tmp/tode_all.txt"
EXTENSIONS_LIST=("*" "Makefile")
EXCLUDES_LIST=("proto" ".git" "target" ".OLD" ".docs" "bin" "ideas" ".vscode" ".gitignore" "tode_rmm.txt" "todep_portable.sh")
INCLUDE_FILES=("/home/user/Documents/Scripts/todep/header.txt")

# -------------------------

if [ ${#DIRS[@]} -eq 0 ]; then
    if [ -z "$1" ]; then
        echo "📁 Sin directorio especificado, usando: $PWD"
        DIRS=("$PWD")
    else
        DIRS=("$1")
    fi
fi

# -------------------------

function generate_tree_section() {
    local paths=("$@")
    echo "📁 Generating directory tree ..." >&2

    local tree_ignore=""
    for dir in "${EXCLUDES_LIST[@]}"; do
        if [[ -z "$tree_ignore" ]]; then
            tree_ignore="$dir"
        else
            tree_ignore="$tree_ignore|$dir"
        fi
    done

    for path in "${paths[@]}"; do
        if [[ -d "$path" ]]; then
            if command -v tree >/dev/null 2>&1; then
                tree -a -I "$tree_ignore" "$path"
            else
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


# -------------------------

function build_prune_args() {
    local excludes=("$@")
    local args=()

    for e in "${excludes[@]}"; do
        args+=(-name "$e" -o -path "*/$e" -o -path "*/$e/*" -o)
    done

    unset 'args[-1]'   # Remove last dangling -o
    echo "${args[@]}"
}

# -------------------------

> "$OUT_LIST"

for f in "${INCLUDE_FILES[@]}"; do
    [ -f "$f" ] && echo "$f" >> "$OUT_LIST"
done

# -------------------------

for DIR in "${DIRS[@]}"; do

    EXT_ARGS=()
    for ext in "${EXTENSIONS_LIST[@]}"; do
        EXT_ARGS+=(-name "$ext" -o)
    done
    unset 'EXT_ARGS[-1]'

    echo "🔍 Buscando archivos ..."

    PRUNE_ARGS=$(build_prune_args "${EXCLUDES_LIST[@]}")

# --- Build prune args as array ---
read -r -a PRUNE_ARGS <<< "$(build_prune_args "${EXCLUDES_LIST[@]}")"

# --- Use array expansion safely ---
find "$DIR" \
    \( -type d "${PRUNE_ARGS[@]}" \) -prune -o \
    \( "${EXT_ARGS[@]}" -type f \) -print \
    >> "$OUT_LIST"

done

# -------------------------

echo "📊 Total de archivos encontrados: $(wc -l < "$OUT_LIST")"
echo "✅ Resultados guardados en: $OUT_LIST"
cat "$OUT_LIST"

# -------------------------

OUT_MERGE="/tmp/merged_all.txt"

{
    generate_tree_section "${DIRS[@]}"
} > "$OUT_MERGE"

# -------------------------

while IFS= read -r file || [ -n "$file" ]; do
    [ -z "$file" ] && continue

    if [ -f "$file" ]; then
        echo -e "\n>>> FILE: $file <<<\n" >> "$OUT_MERGE"
        cat "$file" >> "$OUT_MERGE"
        echo "" >> "$OUT_MERGE"
    fi
done < "$OUT_LIST"

# -------------------------

echo "✅ Merged en: $OUT_MERGE"
echo "📄 Líneas totales: $(wc -l < "$OUT_MERGE")"
