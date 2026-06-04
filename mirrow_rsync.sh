
#!/usr/bin/env bash
# ---------------------------------------------
# Filename: mirrow_rsync.sh
# Version: 1.0
# By: CSUBIRES <cjesuma@proton.me>
# Created: 2024/08/12 07:38:31 by CSUBIRES
# Updated: 2024/10/29 09:24:34 by CSUBIRES
# Description: Script to synchronize folders.
# ---------------------------------------------


# =============================================================================
# mirrow_rsync.sh  –  Sincronización segura de carpetas (local ↔ remoto via SSH)
# Uso:  ./mirrow_rsync.sh             → local  → remoto  (subir)
#       ./mirrow_rsync.sh --down      → remoto → local   (bajar)
#       ./mirrow_rsync.sh --dry       → simulación, no toca nada
#       ./mirrow_rsync.sh --down --dry
# =============================================================================

source ./utils.sh || { echo "No se pudo cargar utils.sh"; exit 1; }

# =============================================================================
# CONFIGURACIÓN  ← edita solo esta sección
# =============================================================================

# Local
LOCAL="/home/user/Documents/box/"

# Remoto  (usuario@host:ruta)
REMOTE_USER="user"
REMOTE_HOST="192.168.18.20"
REMOTE_PATH="/home/user/Documents/box/"
REMOTE="${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}"

# =============================================================================
# PARSEO DE FLAGS
# =============================================================================
MODE="up"       # up | down
DRY="false"

for arg in "$@"; do
    case "$arg" in
        --down) MODE="down" ;;
        --dry)  DRY="true"  ;;
        -h|--help)
            lg_prt "nw" "\nUso:" "./mirrow_rsync.sh [--down] [--dry]\n"
            lg_prt "bw" "  (sin flags)" "Sube: local → remoto"
            lg_prt "bw" "  --down     " "Baja: remoto → local"
            lg_prt "bw" "  --dry      " "Simulación, no modifica nada\n"
            exit 0 ;;
    esac
done

# =============================================================================
# CONSTRUIR SRC / DEST con dirección visual clara
# =============================================================================
if [[ "$MODE" == "up" ]]; then
    SRC="$LOCAL"
    DEST="$REMOTE"
    ARROW="local  →  remoto"
    ARROW_CLR="cy"
else
    SRC="$REMOTE"
    DEST="$LOCAL"
    ARROW="remoto  →  local"
    ARROW_CLR="yc"
fi

# =============================================================================
# RESUMEN ANTES DE ACTUAR
# =============================================================================
lg_prt "nw" "\n\t── Sincronización de carpetas ──\n"
lg_prt "$ARROW_CLR" "\t  Dirección:" "$ARROW"
lg_prt "bw"         "\t  Origen:   " "$SRC"
lg_prt "bw"         "\t  Destino:  " "$DEST"

[[ "$DRY" == "true" ]] && lg_prt "oy" "\n\t  [!] MODO SIMULACIÓN" "no se escribirá nada\n"

# Confirmación explícita — evita el "liarla parda"
echo
read -p "$(echo -e "${PALETTE[y]}\t¿Confirmar sincronización? (S/N): ${PALETTE[x]}")" -n 1 -r
echo -e "\n"
[[ ! $REPLY =~ ^[Ss]$ ]] && { lg_prt "y" "\t[▲] Cancelado\n"; exit 0; }

# =============================================================================
# RSYNC
# =============================================================================
RSYNC_OPTS=(-a --progress --delete --human-readable)
[[ "$DRY" == "true" ]] && RSYNC_OPTS+=(--dry-run)

lg_prt "nw" "\t── Ejecutando rsync ──\n"

if rsync "${RSYNC_OPTS[@]}" "$SRC" "$DEST"; then
    lg_prt "ng" "\n\t[✔] Sincronización completada\n"
else
    lg_prt "ry" "\n\t[✖] rsync terminó con errores" "Revisa la conexión SSH o las rutas\n"
    exit 1
fi

# =============================================================================
# DIFF  (solo tiene sentido en local↔local o si montas el remoto con sshfs)
# =============================================================================
if [[ "$MODE" == "up" && "$REMOTE_HOST" == "localhost" ]] || \
   [[ "$SRC" != *":"* && "$DEST" != *":"* ]]; then
    lg_prt "nw" "\t── Diferencias restantes ──\n"
    if diff -rq "$SRC" "$DEST" &>/dev/null; then
        lg_prt "g" "\t  Los directorios son idénticos"
    else
        diff -r "$SRC" "$DEST"
    fi
    echo
fi
