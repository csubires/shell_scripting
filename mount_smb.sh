#!/usr/bin/env bash
set -euo pipefail

. utils/color.sh
. utils/utils.sh
. .config/smb.conf

PROFILE="${1:-SERVER}"
PROFILE=$(echo "$PROFILE" | tr '[:lower:]' '[:upper:]')
SERVER_IP_VAR="${PROFILE}_SERVER_IP"
SHARE_NAME_VAR="${PROFILE}_SHARE_NAME"
MOUNT_POINT_VAR="${PROFILE}_MOUNT_POINT"
USER_VAR="${PROFILE}_USER"

declare -n CONFIG="$PROFILE"
SERVER_IP="${CONFIG[SERVER_IP]}"
SHARE_NAME="${CONFIG[SHARE_NAME]}"
MOUNT_POINT="${CONFIG[MOUNT_POINT]}"
USER="${CONFIG[USER]}"

function require_var() {
    local value="$1"
    local name="$2"

    if [[ -z "$value" ]]; then
        lg_prt "ry" "Configuración inválida: " $name
        exit 1
    fi
}

function derive_key() {
    local SECRET="/home/$USER/.secret/.smb"
    chk_file "$SECRET"
    local PHRASE
    PHRASE="$(head "$SECRET" -n 4 | tail -1)"
    echo -n "$(echo "$PHRASE" | base64 -d | sha256sum | head -c 32 | base64)"
}

function check_server() {
    lg_prt "w" "Comprobando si el servidor $SERVER_IP está accesible..."
    if ping -c 1 $SERVER_IP &> /dev/null; then
        lg_prt "g" "Servidor $SERVER_IP accesible."
    else
        lg_prt "r" "No se puede alcanzar el servidor $SERVER_IP. Abortando."
        exit 1
    fi
}

function check_mounted() {
    lg_prt "w" "Comprobando si el recurso compartido ya está montado..."
    if mount | grep -q "$SERVER_IP"; then
        lg_prt "y" "El recurso compartido ya está montado en algún punto del sistema."
        exit 0
    fi
}

function mount_share() {
    lg_prt "w" "Intentando montar el recurso compartido $SHARE_NAME desde $SERVER_IP..."

    local KEY
    KEY="$(_derive_key)"

    sudo mount -t cifs //$SERVER_IP/$SHARE_NAME $MOUNT_POINT \
        -o username=$USER,password=$KEY,$MOUNT_OPTIONS

    if [ $? -eq 0 ]; then
        lg_prt "g" "Recurso compartido montado exitosamente en $MOUNT_POINT."
    else
        lg_prt "r" "Error al montar el recurso compartido. Revisando logs..."
        dmesg | tail -n 20
        exit 1
    fi
}

main() {
    _require_var "$SERVER_IP" "$SERVER_IP_VAR"
    _require_var "$SHARE_NAME" "$SHARE_NAME_VAR"

    lg_prt "bw" "Perfil cargado: " $PROFILE
    lg_prt "bw" "Servidor:       " $SERVER_IP
    lg_prt "bw" "Share:          " $SHARE_NAME

    check_server
    check_mounted
    mount_share
}

main
