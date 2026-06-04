#!/usr/bin/env bash

# ==============================================================================
#  backup_config.sh — Backup & documentación de archivos de configuración
#  Uso:
#    ./backup_config.sh md      → genera reporte Markdown
#    ./backup_config.sh copy    → copia archivos a carpeta de destino
#    ./backup_config.sh         → ejecuta ambas opciones
# ==============================================================================

OUT_PATH="/home/user/Documents/GIT/build_setups"
OUT_FILE="$OUT_PATH/⭐ Essentials Configs.md"
COPY_DEST="$OUT_PATH/config"

. ./utils/repomark.sh
. ./config/configs.sh

# ------------------------------------------------------------------------------
clean_config_content() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        sed -E '
            /^[[:space:]]*#/d;
            /^[[:space:]]*\/\//d;
            /^[[:space:]]*$/d;
            s/[[:space:]]+$//;
        ' "$file_path"
    else
        echo "# ERROR: Archivo no encontrado: $file_path"
    fi
}

# ------------------------------------------------------------------------------
cmd_markdown() {
    repomark "$OUT_PATH"
    mkdir -p "$OUT_PATH"

    echo "# Documentación de Archivos de Configuración"  > "$OUT_FILE"
    echo ""                                               >> "$OUT_FILE"
    echo "> Generado automáticamente el $(date)"         >> "$OUT_FILE"
    echo ""                                               >> "$OUT_FILE"

    for name in "${!to_markdown[@]}"; do
        path="${to_markdown[$name]}"
        echo "  → $name ($path)" >&2
        {
            echo "## $name"
            echo ""
            echo "**Archivo:** \`$path\`"
            echo ""
            echo "### Contenido"
            echo ""
            echo '``` bash'
            echo ' '
            clean_config_content "$path"
            echo ' '
            echo '```'
            echo ""
            echo "---"
            echo ""
        } >> "$OUT_FILE"
    done

    {
        echo ""
        echo "> sudo apt install vim nano zsh git curl wget tree bat xclip trash-cli openssl fd-find fzf kitty"
        echo "> sudo apt install zsh-autosuggestions zsh-syntax-highlighting"
        echo "> curl -sS https://starship.rs/install.sh | sh"
        echo "> source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    } >> "$OUT_FILE"

    echo "✔ Reporte generado: $OUT_FILE"
    cp "$OUT_FILE" "/home/user/Documents/Docs/obsidian/⚙ SETUP/"
    echo "✔ Copiado a Obsidian"
}

# ------------------------------------------------------------------------------
cmd_copy() {
    mkdir -p "$COPY_DEST"
    local ok=0 fail=0

    for name in "${!to_copy[@]}"; do
        path="${to_copy[$name]}"
        if [ -e "$path" ]; then
            cp -r "$path" "$COPY_DEST/"
            echo "  ✔ $name  ←  $path" >&2
            (( ok++ ))
        else
            echo "  ✗ $name  — no encontrado: $path" >&2
            (( fail++ ))
        fi
    done

    echo "Archivos copiados: $ok  |  No encontrados: $fail  →  $COPY_DEST"
}

# ------------------------------------------------------------------------------
case "${1:-all}" in
    md|markdown)  cmd_markdown ;;
    copy)         cmd_copy     ;;
    all)          cmd_markdown; cmd_copy ;;
    *)
        echo "Uso: $0 [md|copy|all]"
        echo "  md    → genera reporte Markdown"
        echo "  copy  → copia archivos a $COPY_DEST"
        echo "  all   → ambas (por defecto)"
        exit 1
        ;;
esac