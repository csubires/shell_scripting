#!/usr/bin/env bash
# ---------------------------------------------
# Filename: ${BASH_SOURCE[0]}
# Version: 2.0
# By: CSUBIRES <cjesuma@proton.me>
# Created: 2024/08/12 07:14:59 by CSUBIRES
# Updated: 2025/01/01 00:00:00 by CSUBIRES
# Description: Script used to create a VPN \
# 	connection with Openvpn, VPNBook and ProtonVPN.
# ---------------------------------------------

. utils/color.sh

# Variables globales
#readonly USER="user"								# Usuario local
readonly OVPN_FOLDER="/home/user/Documents/VPN"
readonly KEY="/etc/openvpn/.secret" # Archivos de login de VPN
# Líneas 1-2: credenciales VPNBook | Líneas 3-4: credenciales ProtonVPN
readonly KEY_VPNBOOK_LINE=1
readonly KEY_PROTON_LINE=3

# ── Función: bandera unicode a partir de código de país (ISO 3166-1 alpha-2) ──
function flag() {
    local country
    country=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    local result=""

    for ((i = 0; i < ${#country}; i++)); do
        local char="${country:$i:1}"
        local code
        code=$(printf "%d" "'$char")
        local unicode=$((0x1F1E6 + code - 65))
        result+=$(python3 -c "import sys; sys.stdout.write(chr($unicode))")
    done
    printf "%s" "$result"
}

# ── Archivos de configuración VPNBook ────────────────────────────────────────
# Formato: vpnbook-ca149-tcp443.ovpn  →  clave "ca149"
declare -A file_ovpn
for f in "$OVPN_FOLDER"/vpnbook-*.ovpn; do
    [ -e "$f" ] || continue
    base=$(basename "$f")
    key=${base#vpnbook-}
    key=${key%-tcp443.ovpn}
    file_ovpn["$key"]="$f"
done

# ── Archivos de configuración ProtonVPN ──────────────────────────────────────
# Formato: jp-free-14.protonvpn.tcp.ovpn  →  clave "proton-jp-free-14"
declare -A file_proton
for f in "$OVPN_FOLDER"/*.protonvpn.tcp.ovpn; do
    [ -e "$f" ] || continue
    base=$(basename "$f")
    key=${base%.protonvpn.tcp.ovpn} # ej: jp-free-14
    file_proton["$key"]="$f"
done

# ── Extraer código de país de una clave (primeros 2 chars) ───────────────────
function country_code() {
    echo "${1:0:2}"
}

# ── Leer credenciales del archivo .secret ────────────────────────────────────
# $1 = número de línea (usuario) | $2 = número de línea (contraseña)
function read_creds() {
    local user_line="$1"
    local pass_line=$((user_line + 1))
    local user pass
    user=$(sed -n "${user_line}p" "$KEY")
    pass=$(sed -n "${pass_line}p" "$KEY")
    echo "$user"$'\n'"$pass"
}

# ── Panel de ayuda ────────────────────────────────────────────────────────────
function help_panel() {
    clear

    lg_prt "wtw" "\n" "OPEN VPN STARTER" "\n"
    lg_prt "wobv" "Uso:" "${BASH_SOURCE[0]}" "<Opción>" "<Server>"

    lg_prt "bwr" "\t-c, --country" "\tIniciar conexión con una VPN" "Necesario ROOT"

    lg_prt "wg" "\n\t── VPNBook ──────────────────────────────"
    for k in "${!file_ovpn[@]}"; do
        local cc
        cc=$(country_code "$k")
        local emoji
        emoji=$(flag "$cc")
        lg_prt "gy" "\t$k" "\t$emoji  ${file_ovpn[$k]}"
    done

    lg_prt "wg" "\n\t── ProtonVPN ────────────────────────────"
    for k in "${!file_proton[@]}"; do
        local cc
        cc=$(country_code "$k")
        local emoji
        emoji=$(flag "$cc")
        lg_prt "gy" "\tproton-$k" "\t$emoji  ${file_proton[$k]}"
    done

    lg_prt "bwr" "\n\t-p, --passwrd" "\tCambiar contraseña VPNBook (línea 2)" "Necesario ROOT"
    lg_prt "bwr" "\t-P, --proton-passwrd" "\tCambiar contraseña ProtonVPN (línea 4)" "Necesario ROOT"
    lg_prt "bwr" "\t-r, --reset" "\tResetear la conexión" "Necesario ROOT"
    lg_prt "bw" "\t-h, --help" "\tMostrar ayuda"

    lg_prt "wc" "\n Ejemplos:\n" "\t${BASH_SOURCE[0]} -c ca149"
    lg_prt "c" "\t${BASH_SOURCE[0]} -c proton-jp-free-14"
    lg_prt "c" "\t${BASH_SOURCE[0]} --reset\n"
    exit 0
}

# ── Núcleo compartido de conexión OpenVPN ─────────────────────────────────────
# $1 = archivo .ovpn | $2 = archivo de credenciales temporal | $3 = etiqueta
function connect_ovpn() {
    local ovpn_file="$1"
    local creds_file="$2"
    local label="$3"

    # Comprobar si el cortafuegos está activo
    if ! systemctl is-active --quiet nftables; then
        lg_prt "y" "\n[▲] El cortafuegos (nftables) está deshabilitado\n"
        read -p "¿Habilitar cortafuegos? (S/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Ss]$ ]] || exit 1
        systemctl start nftables
        systemctl enable nftables --quiet
        sleep 3
        clear
    fi

    lg_prt "yw" "\n\tArchivo OVPN:" "$ovpn_file"
    lg_prt "yw" "\tCredenciales:" "$creds_file"

    # 1. Lanzar openvpn en background
    openvpn --auth-nocache \
        --config "$ovpn_file" \
        --auth-user-pass "$creds_file" &
    local vpn_pid=$!

    # 2. Esperar a que tun0 esté activo (máx. 15 s)
    lg_prt "c" "\tConectando..."
    local elapsed=0
    while ! ip link show tun0 &>/dev/null; do
        sleep 1
        ((elapsed++))
        if ((elapsed >= 15)); then
            lg_prt "ry" "[✖] Timeout: tun0 no apareció en 15 s" "Revisa credenciales o servidor"
            kill "$vpn_pid" 2>/dev/null
            exit 1
        fi
    done

    # 3. Espera extra para que la ruta esté operativa
    sleep 2

    # 4. Mostrar IP pública
    local pub_ip
    pub_ip=$(curl -s --max-time 5 ipinfo.io/ip 2>/dev/null || echo "no disponible")
    lg_prt "ng" "\n\t[✔] VPN conectada"
    lg_prt "bw" "\tServidor:" "$label"
    lg_prt "bw" "\tIP pública:" "$pub_ip\n"

    # 5. Esperar a que openvpn termine (bloqueante)
    wait "$vpn_pid"
    local exit_code=$?

    if ((exit_code != 0)); then
        lg_prt "ry" "[✖] OpenVPN terminó con error:" "exit $exit_code"
    else
        lg_prt "y" "[▲] VPN desconectada"
    fi

    exit "$exit_code"
}

# ── Activar VPNBook ───────────────────────────────────────────────────────────
function start_VPN() {
    clear
    local key="$1"

    if [[ -z "${file_ovpn[$key]}" ]]; then
        lg_prt "ry" "[✖] Servidor VPNBook desconocido:" "$key"
        exit 1
    fi

    connect_ovpn "${file_ovpn[$key]}" "$KEY" "$key"
}

# ── Activar ProtonVPN ─────────────────────────────────────────────────────────
function start_proton_VPN() {
    clear
    local key="$1" # ej: jp-free-14  (sin prefijo "proton-")

    if [[ -z "${file_proton[$key]}" ]]; then
        lg_prt "ry" "[✖] Servidor ProtonVPN desconocido:" "$key"
        exit 1
    fi

    # Escribir credenciales ProtonVPN en un archivo temporal seguro
    local tmp_creds
    tmp_creds=$(mktemp /tmp/.proton_creds.XXXXXX)
    chmod 600 "$tmp_creds"
    sed -n "${KEY_PROTON_LINE},$((KEY_PROTON_LINE + 1))p" "$KEY" >"$tmp_creds"
    # Limpiar al salir o en caso de error
    trap "rm -f '$tmp_creds'" EXIT

    local cc emoji
    cc=$(country_code "$key")
    emoji=$(flag "$cc")

    connect_ovpn "${file_proton[$key]}" "$tmp_creds" "proton-$key  $emoji"
}

# ── Cambiar contraseña VPNBook (línea 2 del archivo .secret) ─────────────────
function change_psswd() {
    clear

    lg_prt "yw" "\n\tArchivo PASS:" "\t$KEY"
    lg_prt "vw" "\n\tUser (VPNBook):" "\t$(sed -n '1p' "$KEY")"
    lg_prt "vw" "\tOld Passwrd:" "\t$(sed -n '2p' "$KEY")"
    lg_prt "vg" "\tNew Passwrd:" "\t$1"
    sed -i "2s/.*/$1/" "$KEY"
    lg_prt "g" "\n [✔] Contraseña VPNBook modificada correctamente"
    exit 0
}

# ── Cambiar contraseña ProtonVPN (línea 4 del archivo .secret) ───────────────
function change_proton_psswd() {
    clear

    lg_prt "yw" "\n\tArchivo PASS:" "\t$KEY"
    lg_prt "vw" "\n\tUser (ProtonVPN):" "\t$(sed -n '3p' "$KEY")"
    lg_prt "vw" "\tOld Passwrd:" "\t$(sed -n '4p' "$KEY")"
    lg_prt "vg" "\tNew Passwrd:" "\t$1"
    sed -i "4s/.*/$1/" "$KEY"
    lg_prt "g" "\n [✔] Contraseña ProtonVPN modificada correctamente"
    exit 0
}

# ── Resetear conexión ─────────────────────────────────────────────────────────
function reset_connection() {
    clear

    lg_prt "yw" "[▲] Reseteando conexión" "Espere..."
    service network-manager restart
    sleep 3
    lg_prt "g" "\n [✔] Conexión reseteada"
    exit 0
}

# ── Punto de entrada ──────────────────────────────────────────────────────────
if [[ "$(id -u)" == "0" ]]; then

    if [[ $1 ]]; then
        case "$1" in
        -c | --country)
            if [[ -z "$2" ]]; then
                lg_prt "ry" "[✖] Parámetros insuficientes" "Usa --help"
                exit 1
            fi
            # Detectar si es ProtonVPN por el prefijo "proton-"
            if [[ "$2" == proton-* ]]; then
                start_proton_VPN "${2#proton-}"
            else
                start_VPN "$2"
            fi
            ;;
        -p | --passwrd)
            [[ $2 ]] && change_psswd "$2" || lg_prt "ry" "[✖] Parámetros insuficientes" "Usa --help"
            ;;
        -P | --proton-passwrd)
            [[ $2 ]] && change_proton_psswd "$2" || lg_prt "ry" "[✖] Parámetros insuficientes" "Usa --help"
            ;;
        -r | --reset)
            reset_connection
            ;;
        -h | --help | *)
            help_panel
            ;;
        esac
        exit 0
    else
        lg_prt "ry" "[✖] Parámetros no válidos o insuficientes." "Usa --help"
    fi

else
    lg_prt "r" "[✖] Es necesario tener permisos ROOT"
    exit 1
fi
