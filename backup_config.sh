#!/bin/bash

# Script standalone con configuraciones incorporadas
OUTPUT_FILE="output/⭐ Essentials Configs.md"

# Array con las configuraciones (name, path)
source ./config/configs.sh

# Función para limpiar comentarios y espacios
clean_config_content() {
    local file_path="$1"

    if [ -f "$file_path" ]; then
        # Eliminar comentarios (# y //) y líneas vacías, pero preservar sangrado
        sed -E '
            /^[[:space:]]*#/d;           # Eliminar líneas que comienzan con #
            /^[[:space:]]*\/\//d;        # Eliminar líneas que comienzan con //
            /^[[:space:]]*$/d;           # Eliminar líneas vacías
            s/[[:space:]]+$//;           # Eliminar espacios al final de línea
            #s/`/\\`/g;                   # Escapar backticks
            #s/'\''/\\'\''/g;             # Escapar comillas simples
        ' "$file_path"
    else
        echo "# ERROR: Archivo no encontrado: $file_path"
    fi
}

# Crear archivo Markdown
echo "# Documentación de Archivos de Configuración" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "> Generado automáticamente el $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Procesar cada configuración
for name in "${!to_markdown[@]}"; do
    path="${to_markdown[$name]}"

    echo "Procesando: $name ($path)" >&2

    echo "## $name" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "**Archivo:** \`$path\`" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "### Contenido" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo '``` bash' >> "$OUTPUT_FILE"
    echo ' ' >> "$OUTPUT_FILE"
    clean_config_content "$path" >> "$OUTPUT_FILE"
    echo ' ' >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "---" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    cp "$path" "/home/user/Documents/Docs/configs"
done

echo "" >> "$OUTPUT_FILE"
echo "> sudo apt install vim nano zsh git curl wget tree bat xclip trash-cli openssl fd-find fzf kitty" >> "$OUTPUT_FILE"
echo "> sudo apt install zsh-autosuggestions zsh-syntax-highlighting" >> "$OUTPUT_FILE"
echo "> curl -sS https://starship.rs/install.sh | sh" >> "$OUTPUT_FILE"
echo "> source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> "$OUTPUT_FILE"

#git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
#git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

echo "Documentación generada en: $OUTPUT_FILE"
