#!/bin/bash

# Ruta de backup destino (cambia si quieres otro sitio)
DESTINO_BASE="/home/kali/Documents/BACKUP/rsync_backup"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

hacer_backup_si_cambios() {
    local ORIGEN="$1"
    local NOMBRE="$2"
    local DESTINO="$DESTINO_BASE/$NOMBRE"

    echo ""
    echo "📁 Revisando cambios en: $ORIGEN"
    echo "📂 Destino espejo: $DESTINO"

    # Crear carpeta destino si no existe
    mkdir -p "$DESTINO"

    # Ejecutar rsync en modo espejo y capturar salida
    # --delete para eliminar archivos que ya no existen en origen
    # --itemize-changes para ver qué cambió
    CHANGES=$(rsync -a --delete --itemize-changes "$ORIGEN/" "$DESTINO/")

    if [ -n "$CHANGES" ]; then
        echo "✅ Cambios detectados y sincronizados:"
        echo "$CHANGES"
        echo "Backup actualizado: $TIMESTAMP"
    else
        echo "🔁 Sin cambios detectados. Backup omitido."
    fi
}

# Backups con rsync modo espejo
hacer_backup_si_cambios "/home/kali/Documents/Ejercicios_seguridad_informatica_2025/Cristobal" "Cristobal"
hacer_backup_si_cambios "/home/kali/Documents/Ejercicios_seguridad_informatica_2025/POWER POINT POR MÓDULOS" "Teoria"

echo ""
echo "✅ Todo completado."
