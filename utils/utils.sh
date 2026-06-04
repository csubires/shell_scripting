#!/usr/bin/env bash

function ctrl_c() {
    lg_prt "y" "[▲] Exiting due to interrupt"
    exit 1
}

# Execute on Ctrl+C
trap ctrl_c INT

#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  checks.sh  —  Librería de funciones de comprobación para Bash
#  Requiere: source colors.sh  (lg_prt + PALETTE)
#  Uso:      source /ruta/checks.sh
# ═══════════════════════════════════════════════════════════════
#
#  FUNCIONES DISPONIBLES:
#
#  ── Filesystem ──────────────────────────────────────────────
#    chk_path    <ruta>               → Ruta existe (file o dir)
#    chk_file    <archivo>            → Es un archivo regular
#    chk_dir     <directorio>         → Es un directorio
#    chk_readable  <ruta>             → Tiene permiso de lectura
#    chk_writable  <ruta>             → Tiene permiso de escritura
#    chk_executable <ruta>            → Tiene permiso de ejecución
#
#  ── Procesos ────────────────────────────────────────────────
#    chk_pid     <pid>                → PID existe en el sistema
#    chk_process <nombre>             → Proceso corriendo por nombre
#
#  ── Servicios systemd ───────────────────────────────────────
#    chk_service <nombre>             → Servicio activo (running)
#    chk_service_enabled <nombre>     → Servicio habilitado (enabled)
#
#  ── Red ─────────────────────────────────────────────────────
#    chk_port    <puerto> [host]      → Puerto abierto/escuchando
#    chk_url     <url>                → URL responde HTTP 2xx/3xx
#
#  ── Programas ───────────────────────────────────────────────
#    chk_cmd     <comando>            → Comando disponible en PATH
#    chk_version <cmd> <min_version>  → Versión mínima instalada
#
#  ── Sistema ─────────────────────────────────────────────────
#    chk_root                         → Script ejecutado como root
#    chk_os      <linux|mac|...>      → Sistema operativo coincide
#    chk_var     <nombre_variable>    → Variable definida y no vacía
#
#  TODAS las funciones:
#    • Devuelven 0 (éxito) o 1 (fallo)
#    • Imprimen mensaje de error con lg_prt si fallan
#    • Son silenciosas en caso de éxito (salvo chk_* de info)
# ═══════════════════════════════════════════════════════════════

# ── Guardia ─────────────────────────────────────────────────────
if [[ -z "${PALETTE[*]+_}" ]] || ! declare -f lg_prt &>/dev/null; then
    echo -e "\e[91m[checks] Error: haz 'source colors.sh' antes de cargar checks.sh\e[0m" >&2
    exit 1
fi

# ════════════════════════════════════════════════════════════════
#  FILESYSTEM
# ════════════════════════════════════════════════════════════════

# chk_path <ruta>
# Comprueba que la ruta existe (sea archivo, directorio o enlace)
function chk_path() {
    local path="$1"
    if [[ -z "$path" ]]; then
        lg_prt "r" "Error (chk_path): Se requiere una ruta como argumento."
        exit 1
    fi
    if ! realpath -e "$path" &>/dev/null; then
        lg_prt "r" "Error (chk_path): La ruta \"$path\" no existe."
        exit 1
    fi
}

# chk_file <archivo>
# Comprueba que la ruta existe Y es un archivo regular
function chk_file() {
    local file="$1"
    if [[ -z "$file" ]]; then
        lg_prt "r" "Error (chk_file): Se requiere un archivo como argumento."
        exit 1
    fi
    if [[ ! -e "$file" ]]; then
        lg_prt "r" "Error (chk_file): El archivo \"$file\" no existe."
        exit 1
    fi
    if [[ ! -f "$file" ]]; then
        lg_prt "r" "Error (chk_file): \"$file\" no es un archivo regular (es un directorio u otro tipo)."
        exit 1
    fi
}

# chk_dir <directorio>
# Comprueba que la ruta existe Y es un directorio
function chk_dir() {
    local dir="$1"
    if [[ -z "$dir" ]]; then
        lg_prt "r" "Error (chk_dir): Se requiere un directorio como argumento."
        exit 1
    fi
    if [[ ! -e "$dir" ]]; then
        lg_prt "r" "Error (chk_dir): El directorio \"$dir\" no existe."
        exit 1
    fi
    if [[ ! -d "$dir" ]]; then
        lg_prt "r" "Error (chk_dir): \"$dir\" no es un directorio (es un archivo u otro tipo)."
        exit 1
    fi
}

# chk_readable <ruta>
# Comprueba que la ruta existe y tiene permiso de lectura
function chk_readable() {
    local path="$1"
    if [[ -z "$path" ]]; then
        lg_prt "r" "Error (chk_readable): Se requiere una ruta como argumento."
        exit 1
    fi
    if ! chk_path "$path" 2>/dev/null; then
        lg_prt "r" "Error (chk_readable): La ruta \"$path\" no existe."
        exit 1
    fi
    if [[ ! -r "$path" ]]; then
        lg_prt "r" "Error (chk_readable): Sin permiso de lectura en \"$path\"."
        exit 1
    fi
}

# chk_writable <ruta>
# Comprueba que la ruta existe y tiene permiso de escritura
function chk_writable() {
    local path="$1"
    if [[ -z "$path" ]]; then
        lg_prt "r" "Error (chk_writable): Se requiere una ruta como argumento."
        exit 1
    fi
    if ! chk_path "$path" 2>/dev/null; then
        lg_prt "r" "Error (chk_writable): La ruta \"$path\" no existe."
        exit 1
    fi
    if [[ ! -w "$path" ]]; then
        lg_prt "r" "Error (chk_writable): Sin permiso de escritura en \"$path\"."
        exit 1
    fi
}

# chk_executable <ruta>
# Comprueba que la ruta existe y tiene permiso de ejecución
function chk_executable() {
    local path="$1"
    if [[ -z "$path" ]]; then
        lg_prt "r" "Error (chk_executable): Se requiere una ruta como argumento."
        exit 1
    fi
    if ! chk_path "$path" 2>/dev/null; then
        lg_prt "r" "Error (chk_executable): La ruta \"$path\" no existe."
        exit 1
    fi
    if [[ ! -x "$path" ]]; then
        lg_prt "r" "Error (chk_executable): Sin permiso de ejecución en \"$path\"."
        exit 1
    fi
}

# ════════════════════════════════════════════════════════════════
#  PROCESOS
# ════════════════════════════════════════════════════════════════

# chk_pid <pid>
# Comprueba que un PID existe en el sistema en este momento
function chk_pid() {
    local pid="$1"
    if [[ -z "$pid" ]]; then
        lg_prt "r" "Error (chk_pid): Se requiere un PID como argumento."
        exit 1
    fi
    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        lg_prt "r" "Error (chk_pid): \"$pid\" no es un PID válido (debe ser numérico)."
        exit 1
    fi
    if ! kill -0 "$pid" 2>/dev/null; then
        lg_prt "r" "Error (chk_pid): No existe ningún proceso con PID $pid."
        exit 1
    fi
}

# chk_process <nombre>
# Comprueba que al menos un proceso con ese nombre está corriendo
function chk_process() {
    local name="$1"
    if [[ -z "$name" ]]; then
        lg_prt "r" "Error (chk_process): Se requiere un nombre de proceso como argumento."
        exit 1
    fi
    if ! pgrep -x "$name" &>/dev/null; then
        lg_prt "r" "Error (chk_process): El proceso \"$name\" no está en ejecución."
        exit 1
    fi
}

# ════════════════════════════════════════════════════════════════
#  SERVICIOS SYSTEMD
# ════════════════════════════════════════════════════════════════

# chk_service <nombre>
# Comprueba que el servicio systemd está activo (running)
function chk_service() {
    local svc="$1"
    if [[ -z "$svc" ]]; then
        lg_prt "r" "Error (chk_service): Se requiere el nombre del servicio como argumento."
        exit 1
    fi
    if ! command -v systemctl &>/dev/null; then
        lg_prt "y" "Aviso (chk_service): systemctl no está disponible en este sistema."
        exit 1
    fi
    if ! systemctl is-active --quiet "$svc"; then
        local state
        state=$(systemctl is-active "$svc" 2>/dev/null || echo "desconocido")
        lg_prt "r" "Error (chk_service): El servicio \"$svc\" no está activo (estado: $state)."
        exit 1
    fi
}

# chk_service_enabled <nombre>
# Comprueba que el servicio systemd está habilitado (arranca con el sistema)
function chk_service_enabled() {
    local svc="$1"
    if [[ -z "$svc" ]]; then
        lg_prt "r" "Error (chk_service_enabled): Se requiere el nombre del servicio como argumento."
        exit 1
    fi
    if ! command -v systemctl &>/dev/null; then
        lg_prt "y" "Aviso (chk_service_enabled): systemctl no está disponible en este sistema."
        exit 1
    fi
    if ! systemctl is-enabled --quiet "$svc" 2>/dev/null; then
        local state
        state=$(systemctl is-enabled "$svc" 2>/dev/null || echo "desconocido")
        lg_prt "r" "Error (chk_service_enabled): El servicio \"$svc\" no está habilitado (estado: $state)."
        exit 1
    fi
}

# ════════════════════════════════════════════════════════════════
#  RED
# ════════════════════════════════════════════════════════════════

# chk_port <puerto> [host]
# Comprueba que un puerto está abierto/escuchando
# host por defecto: 127.0.0.1
function chk_port() {
    local port="$1"
    local host="${2:-127.0.0.1}"

    if [[ -z "$port" ]]; then
        lg_prt "r" "Error (chk_port): Se requiere un número de puerto como argumento."
        exit 1
    fi
    if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
        lg_prt "r" "Error (chk_port): \"$port\" no es un puerto válido (1-65535)."
        exit 1
    fi

    # Intentar con ss, luego netstat, luego nc como fallback
    if command -v ss &>/dev/null; then
        if ss -tnlp 2>/dev/null | grep -qE ":${port}\b"; then
            exit 0
        fi
    elif command -v netstat &>/dev/null; then
        if netstat -tnlp 2>/dev/null | grep -qE ":${port}\b"; then
            exit 0
        fi
    fi

    # Fallback: intento de conexión TCP
    if command -v nc &>/dev/null; then
        if nc -z -w2 "$host" "$port" &>/dev/null; then
            exit 0
        fi
    fi

    lg_prt "r" "Error (chk_port): El puerto $port no está abierto en $host."
    exit 1
}

# chk_url <url>
# Comprueba que una URL responde con código HTTP 2xx o 3xx
function chk_url() {
    local url="$1"
    if [[ -z "$url" ]]; then
        lg_prt "r" "Error (chk_url): Se requiere una URL como argumento."
        exit 1
    fi
    if ! command -v curl &>/dev/null; then
        lg_prt "y" "Aviso (chk_url): curl no está instalado, no se puede verificar la URL."
        exit 1
    fi
    local code
    code=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 --location "$url" 2>/dev/null)
    if [[ "$code" =~ ^[23] ]]; then
        exit 0
    fi
    lg_prt "r" "Error (chk_url): La URL \"$url\" no responde correctamente (HTTP $code)."
    exit 1
}

# ════════════════════════════════════════════════════════════════
#  PROGRAMAS
# ════════════════════════════════════════════════════════════════

# chk_cmd <comando>
# Comprueba que un comando está disponible en el PATH
function chk_cmd() {
    local cmd="$1"
    if [[ -z "$cmd" ]]; then
        lg_prt "r" "Error (chk_cmd): Se requiere un nombre de comando como argumento."
        exit 1
    fi
    if ! command -v "$cmd" &>/dev/null; then
        lg_prt "r" "Error (chk_cmd): El comando \"$cmd\" no está instalado o no está en el PATH."
        exit 1
    fi
}

# chk_version <comando> <versión_mínima>
# Comprueba que un comando existe y su versión es >= versión_mínima
# La versión se extrae con --version y se compara con sort -V
# Ejemplo: chk_version python3 3.10.0
function chk_version() {
    local cmd="$1"
    local min_ver="$2"

    if [[ -z "$cmd" || -z "$min_ver" ]]; then
        lg_prt "r" "Error (chk_version): Se requieren <comando> y <versión_mínima>."
        exit 1
    fi
    if ! command -v "$cmd" &>/dev/null; then
        lg_prt "r" "Error (chk_version): El comando \"$cmd\" no está instalado."
        exit 1
    fi

    # Extraer la primera línea de --version y la primera secuencia x.y.z
    local current_ver
    current_ver=$("$cmd" --version 2>&1 | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)

    if [[ -z "$current_ver" ]]; then
        lg_prt "y" "Aviso (chk_version): No se pudo determinar la versión de \"$cmd\"."
        exit 1
    fi

    # Comparar con sort -V: la versión mínima debe aparecer primero o ser igual
    local lowest
    lowest=$(printf '%s\n%s' "$min_ver" "$current_ver" | sort -V | head -n1)

    if [[ "$lowest" != "$min_ver" ]]; then
        lg_prt "r" "Error (chk_version): \"$cmd\" tiene versión $current_ver pero se requiere >= $min_ver."
        exit 1
    fi
}

# ════════════════════════════════════════════════════════════════
#  SISTEMA
# ════════════════════════════════════════════════════════════════

# chk_root
# Comprueba que el script se está ejecutando como root
function chk_root() {
    if [[ "$EUID" -ne 0 ]]; then
        lg_prt "r" "Error (chk_root): Este script debe ejecutarse como root (usa sudo)."
        exit 1
    fi
}

# chk_os <sistema>
# Comprueba el sistema operativo. Valores: linux, mac, windows, freebsd
function chk_os() {
    local expected="${1,,}"   # lowercase
    if [[ -z "$expected" ]]; then
        lg_prt "r" "Error (chk_os): Se requiere el SO esperado como argumento (linux, mac, freebsd…)."
        exit 1
    fi

    local actual
    case "$(uname -s)" in
        Linux*)   actual="linux"   ;;
        Darwin*)  actual="mac"     ;;
        CYGWIN*|MINGW*|MSYS*) actual="windows" ;;
        FreeBSD*) actual="freebsd" ;;
        *)        actual="unknown" ;;
    esac

    if [[ "$actual" != "$expected" ]]; then
        lg_prt "r" "Error (chk_os): Se esperaba \"$expected\" pero el sistema es \"$actual\"."
        exit 1
    fi
}

# chk_var <nombre_de_variable>
# Comprueba que una variable está definida y no es una cadena vacía
# Uso: chk_var TELEGRAM_TOKEN   (pasa el nombre, no el valor)
function chk_var() {
    local var_name="$1"
    if [[ -z "$var_name" ]]; then
        lg_prt "r" "Error (chk_var): Se requiere el nombre de la variable como argumento."
        exit 1
    fi
    if [[ -z "${!var_name+_}" ]]; then
        lg_prt "r" "Error (chk_var): La variable \"\$$var_name\" no está definida."
        exit 1
    fi
    if [[ -z "${!var_name}" ]]; then
        lg_prt "r" "Error (chk_var): La variable \"\$$var_name\" está definida pero vacía."
        exit 1
    fi
}
