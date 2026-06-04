#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  progressbar.sh  —  Librería de barra de progreso para Bash
#  Requiere: source color.sh  (lg_prt + PALETTE)
# ═══════════════════════════════════════════════════════════════
#
#  pb_start  <total> [título]      → Inicializa la barra
#  pb_update <actual> [mensaje]    → Actualiza el progreso
#  pb_step   [mensaje]             → Avanza un paso (+1)
#  pb_done   [mensaje_final]       → Finaliza y muestra resumen
#  pb_fail   [mensaje_error]       → Finaliza con error
#  pb_reset                        → Reinicia estado sin limpiar pantalla
#
#  PB_WIDTH      → Ancho de la barra (defecto: auto desde tput, máx 60)
#  PB_CHAR_FILL  → Carácter relleno  (defecto: ━)
#  PB_CHAR_EMPTY → Carácter vacío    (defecto: ╌)
#  PB_COLOR      → Clave PALETTE     (defecto: c)
#  PB_SHOW_ETA   → Mostrar ETA       (defecto: true)
#  PB_SILENT     → Suprimir salida   (defecto: false)
# ═══════════════════════════════════════════════════════════════

if [[ -z "${PALETTE[*]+_}" ]] || ! declare -f lg_prt &>/dev/null; then
    echo -e "\e[91m[progressbar] Error: haz 'source color.sh' antes de cargar progressbar.sh\e[0m" >&2
    return 1
fi

# ── Estado interno ───────────────────────────────────────────────
PB_TOTAL=0
PB_CURRENT=0
PB_TITLE=""
PB_START_TS=0
PB_ACTIVE=false

# ── Utilidades internas ──────────────────────────────────────────

function pb_timestamp() {
    date +%s%3N
}

function pb_format_time() {
    local ms=$1
    local s=$(( ms / 1000 ))
    if   (( s < 60 ));   then printf "%ds"             "$s"
    elif (( s < 3600 )); then printf "%dm %02ds"       "$(( s/60 ))"   "$(( s%60 ))"
    else                      printf "%dh %02dm %02ds" "$(( s/3600 ))" "$(( (s%3600)/60 ))" "$(( s%60 ))"
    fi
}

function pb_auto_width() {
    local cols
    cols=$(tput cols 2>/dev/null || echo 80)
    local w=$(( cols / 2 ))
    (( w > 60 )) && w=60
    (( w < 10 )) && w=10
    echo "$w"
}

function pb_render() {
    [[ "${PB_SILENT:-false}" == "true" ]] && return 0

    local current=$1
    local total=$2
    local msg="${3:-}"

    local width="${PB_WIDTH:-$(pb_auto_width)}"
    local fill_char="${PB_CHAR_FILL:-━}"
    local empty_char="${PB_CHAR_EMPTY:-╌}"
    local show_eta="${PB_SHOW_ETA:-true}"

    local reset="${PALETTE[x]}"
    local bold="${PALETTE[n]}"
    local color="${PALETTE[${PB_COLOR:-c}]:-${PALETTE[c]}}"

    [[ "$current" =~ ^[0-9]+$ ]] || current=0
    [[ "$total"   =~ ^[0-9]+$ ]] || total=1
    (( total < 1 )) && total=1
    (( current > total )) && current=$total

    local pct=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))

    local bar_filled="" bar_empty="" i
    for (( i=0; i<filled; i++ )); do bar_filled+="$fill_char"; done
    for (( i=0; i<empty;  i++ )); do bar_empty+="$empty_char"; done

    # ETA — todo en segundos para evitar overflow
    local eta_str=""
    if [[ "$show_eta" == "true" ]]; then
        local now; now=$(pb_timestamp)
        local elapsed_ms=$(( now - PB_START_TS ))
        if (( current > 0 && current < total )); then
            local rate_ms_per_step=$(( elapsed_ms / current ))
            local remaining_ms=$(( (total - current) * rate_ms_per_step ))
            eta_str="  ETA $(pb_format_time "$remaining_ms")"
        elif (( current >= total && elapsed_ms > 0 )); then
            eta_str="  $(pb_format_time "$elapsed_ms")"
        fi
    fi

    local short_msg=""
    if [[ -n "$msg" ]]; then
        short_msg=" ${msg:0:35}"
        (( ${#msg} > 35 )) && short_msg+="…"
    fi

    # \r + \033[K borra hasta el final de línea — evita residuos de mensajes anteriores
    printf "\r\033[K  %s%s[%s%s%s%s%s%s]%s  %d%%  %d/%d%s%s\033[0m" \
        "$color" "$bold" \
        "$reset" "$color" "$bar_filled" \
        "$reset" "$color" "$bar_empty" \
        "$reset" \
        "$pct" "$current" "$total" \
        "$eta_str" "$short_msg"
}

# ── API pública ──────────────────────────────────────────────────

function pb_start() {
    PB_TOTAL="${1:?pb_start requiere el total como primer argumento}"
    PB_CURRENT=0
    PB_TITLE="${2:-}"
    PB_START_TS=$(pb_timestamp)
    PB_ACTIVE=true

    [[ "${PB_SILENT:-false}" == "true" ]] && return 0

    local key="${PB_COLOR:-c}"
    echo ""
    [[ -n "$PB_TITLE" ]] && lg_prt "${key}n" "▶" "$PB_TITLE"
    pb_render 0 "$PB_TOTAL" ""
}

function pb_update() {
    if [[ "$PB_ACTIVE" != "true" ]]; then
        lg_prt "y" "[pb_update] Barra no iniciada — llama pb_start primero"
        return 1
    fi
    local value="${1:?pb_update requiere el valor actual}"
    PB_CURRENT="$value"
    (( PB_CURRENT > PB_TOTAL )) && PB_CURRENT=$PB_TOTAL
    pb_render "$PB_CURRENT" "$PB_TOTAL" "${2:-}"
}

function pb_step() {
    if [[ "$PB_ACTIVE" != "true" ]]; then
        lg_prt "y" "[pb_step] Barra no iniciada — llama pb_start primero"
        return 1
    fi
    PB_CURRENT=$(( PB_CURRENT + 1 ))
    (( PB_CURRENT > PB_TOTAL )) && PB_CURRENT=$PB_TOTAL
    pb_render "$PB_CURRENT" "$PB_TOTAL" "${1:-}"
}

function pb_done() {
    local msg="${1:-Completado}"
    local key="${PB_COLOR:-c}"
    pb_render "$PB_TOTAL" "$PB_TOTAL" ""
    echo ""
    [[ "${PB_SILENT:-false}" != "true" ]] && lg_prt "${key}n" "✔" "$msg"
    echo ""
    PB_ACTIVE=false
}

function pb_fail() {
    local msg="${1:-Error}"
    pb_render "$PB_CURRENT" "$PB_TOTAL" ""
    echo ""
    [[ "${PB_SILENT:-false}" != "true" ]] && lg_prt "rn" "✘" "$msg"
    echo ""
    PB_ACTIVE=false
}

function pb_reset() {
    PB_TOTAL=0
    PB_CURRENT=0
    PB_TITLE=""
    PB_START_TS=0
    PB_ACTIVE=false
}
