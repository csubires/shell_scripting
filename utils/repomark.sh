#!/usr/bin/env bash
# =============================================================================
#  repomark — Crea (o rota) un archivo de marca de creación en un repositorio
#
#  Uso:
#    source repomark.sh
#    repomark /ruta/al/repo
#    repomark .                  # directorio actual
#
#  Estrategia de detección:
#    1. Glob rápido:   find "$dir" -maxdepth 1 -name ".repomark_*"
#    2. Tag interior:  grep -q "^REPOMARK_CREATED" "$file"   (red de seguridad)
# =============================================================================

repomark() {
  # ── 0. Validar argumento ──────────────────────────────────────────────────
  local dir="${1:?Uso: repomark <directorio>}"

  if [[ ! -d "$dir" ]]; then
    echo "[repomark] ERROR: '$dir' no es un directorio." >&2
    return 1
  fi

  # Normalizar ruta (elimina trailing slash, resuelve .)
  dir="$(cd "$dir" && pwd)"

  # ── 1. Timestamp para el archivo NUEVO ───────────────────────────────────
  local now
  now="$(date '+%Y-%m-%d_%H-%M-%S')"   # ej: 2025-04-03_14-32-05
                                         # (sin ':' → compatible con todos los FS)

  local prefix=".repomark_"
  local new_file="${dir}/${prefix}${now}"

  # ── 2. Buscar marca existente (por nombre Y por tag interior) ─────────────
  local existing=""

  # Búsqueda primaria: glob por prefijo (rápida, O(1) en práctica)
  while IFS= read -r -d '' candidate; do
    # Verificación secundaria: confirmar que el tag interior está presente
    if grep -q "^REPOMARK_CREATED" "$candidate" 2>/dev/null; then
      existing="$candidate"
      break
    fi
  done < <(find "$dir" -maxdepth 1 -name "${prefix}*" -print0 2>/dev/null)

  # ── 3. Si ya existe → renombrar a fecha actual ────────────────────────────
  if [[ -n "$existing" ]]; then
    local backup_name="${dir}/${prefix}${now}"

    # Evitar colisión en el improbable caso de mismo segundo
    if [[ "$existing" == "$backup_name" ]]; then
      backup_name="${backup_name}_1"
    fi

    mv "$existing" "$backup_name"
    echo "[repomark] Marca anterior renombrada:"
    echo "           $(basename "$existing") → $(basename "$backup_name")"

    # Actualizar el contenido para reflejar la nueva fecha
    {
      echo "REPOMARK_CREATED"
      echo "original : $(grep '^original' "$backup_name" 2>/dev/null | head -1 | cut -d: -f2- | xargs || echo 'desconocida')"
      echo "updated  : ${now//_/ }"   # formato legible: 2025-04-03 14-32-05
      echo "path     : $dir"
    } > "$backup_name"

    echo "[repomark] Contenido actualizado en: $(basename "$backup_name")"
    return 0
  fi

  # ── 4. No existe → crear marca nueva ─────────────────────────────────────
  {
    echo "REPOMARK_CREATED"
    echo "original : ${now//_/ }"   # formato legible
    echo "path     : $dir"
  } > "$new_file"

  echo "[repomark] Marca creada: $(basename "$new_file")"
  echo "           en: $dir"
}
