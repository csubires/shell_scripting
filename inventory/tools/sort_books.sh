#!/bin/bash
# Script: organizar_libros.sh
# Objetivo: Renombrar y clasificar archivos PDF según temática (sin usar listado)

# --- Función para limpiar el nombre ---
limpiar_nombre() {
    local nombre="$1"
    nombre=$(echo "$nombre" | sed -E 's/\([^)]*\)//g')   # quitar paréntesis y contenido
    nombre=$(echo "$nombre" | tr -s ' ')                 # eliminar espacios dobles
    nombre=$(echo "$nombre" | sed -E 's/^ *//;s/ *$//')  # quitar espacios extremos
    echo "$nombre"
}

# --- Función para categorizar ---
categorizar() {
    local nombre_lower
    nombre_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')

    if [[ $nombre_lower =~ (ciber|hack|pentest|security|cyber|osint|rootkit|metasploit|wireshark|wazuh) ]]; then
        echo "Ciberseguridad"
    elif [[ $nombre_lower =~ (python) ]]; then
        echo "Python"
    elif [[ $nombre_lower =~ (linux|ubuntu|systemd|bash|grep|sed|awk|shell|powershell) ]]; then
        echo "Linux"
    elif [[ $nombre_lower =~ (c\+\+|cpp|cmake|c programming) ]]; then
        echo "C++"
    elif [[ $nombre_lower =~ (java) ]]; then
        echo "Java"
    elif [[ $nombre_lower =~ (php|javascript|node\.js|html|css|web|flask|django|sass) ]]; then
        echo "Desarrollo_Web"
    elif [[ $nombre_lower =~ (sql|mysql|mariadb|database) ]]; then
        echo "Bases_de_Datos"
    elif [[ $nombre_lower =~ (docker|devops) ]]; then
        echo "DevOps"
    elif [[ $nombre_lower =~ (data|algorithm|algoritmo|estructuras|machine learning|ai|inteligencia artificial) ]]; then
        echo "Ciencia_de_Datos"
    else
        echo "Otros"
    fi
}

# --- Buscar y procesar todos los PDFs ---
# Usa find para recorrer el directorio actual (sin meterse en las carpetas de destino)
for archivo in *.pdf; do
    [[ ! -f "$archivo" ]] && continue  # saltar si no hay PDFs

    base=$(basename "${archivo%.pdf}")
    nuevo_nombre=$(limpiar_nombre "$base").pdf
    categoria=$(categorizar "$nuevo_nombre")

    mkdir -p "$categoria"
    destino="$categoria/$nuevo_nombre"

    # --- Evitar sobrescritura ---
    if [[ -e "$destino" ]]; then
        i=1
        while [[ -e "$categoria/${nuevo_nombre%.pdf} ($i).pdf" ]]; do
            ((i++))
        done
        destino="$categoria/${nuevo_nombre%.pdf} ($i).pdf"
    fi

    mv -v "$archivo" "$destino"
done
