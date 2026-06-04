#!/usr/bin/env bash
# =============================================================================
#  menu.sh — Sistema de ayuda y despacho de comandos
#  Compatible con ejecución directa (./script.sh) y sourced (source script.sh)
# =============================================================================

# ── Detectar si estamos siendo sourced o ejecutados ──────────────────────────
# Usado internamente para decidir exit vs return
_MENU_IS_SOURCED=false
(return 0 2>/dev/null) && _MENU_IS_SOURCED=true

function menu_exit() {
    local code="${1:-0}"
    if [[ "$_MENU_IS_SOURCED" == "true" ]]; then
        return "$code"
    else
        exit "$code"
    fi
}

# =============================================================================
#  render_help
#  Renderiza el panel de ayuda basado en HELP_META y HELP_OPTIONS
#
#  Opciones de comportamiento (variables):
#    MENU_HELP_CLEAR  – "true"|"false"  limpiar pantalla antes (defecto: true)
# =============================================================================
function render_help() {
    local sep="${HELP_SEP:-|}"
    local RST="${PALETTE[x]}"
    local TITLE_CLR="${PALETTE[n]}${PALETTE[c]}"
    local SECTION_CLR="${PALETTE[n]}${PALETTE[y]}"
    local OPT_CLR="${PALETTE[n]}${PALETTE[b]}"
    local VAL_CLR="${PALETTE[g]}"
    local DESC_CLR="${PALETTE[w]}"
    local NOTE_CLR="${PALETTE[v]}"
    local EX_CLR="${PALETTE[c]}"
    local EX_CMT_CLR="${PALETTE[o]}"
    local LABEL_CLR="${PALETTE[n]}${PALETTE[w]}"

    [[ "${MENU_HELP_CLEAR:-true}" == "true" ]] && printf '\033[H\033[2J\033[3J'

    local title="${HELP_META[title]:-Help}"
    echo -e "\n  ${TITLE_CLR}━━━  ${title}  ━━━${RST}\n"

    local script="${HELP_META[script]:-./script.sh}"
    local usage="${HELP_META[usage]:-}"
    echo -e "  ${LABEL_CLR}Uso:${RST}  ${SECTION_CLR}${script}${RST}  ${DESC_CLR}${usage}${RST}\n"

    local line type f1 f2 f3
    for line in "${HELP_OPTIONS[@]}"; do
        # Leer exactamente 4 campos, el resto va a f3 (por si f3 contiene el sep)
        IFS="$sep" read -r type f1 f2 f3 <<< "$line"

        case "$type" in
            section)
                echo -e "\n  ${SECTION_CLR}▸ ${f1}${RST}"
                ;;
            option)
                printf "    ${OPT_CLR}%-22s${RST}  ${DESC_CLR}%s${RST}" "$f1" "$f2"
                [[ -n "$f3" ]] && printf "  ${NOTE_CLR}%s${RST}" "$f3"
                echo
                ;;
            value)
                printf "      ${VAL_CLR}%-20s${RST}  ${DESC_CLR}%s${RST}" "$f1" "$f2"
                [[ -n "$f3" ]] && printf "  ${NOTE_CLR}%s${RST}" "$f3"
                echo
                ;;
            example)
                printf "    ${EX_CLR}%s${RST}" "$f1"
                [[ -n "$f2" ]] && printf "   ${EX_CMT_CLR}# %s${RST}" "$f2"
                echo
                ;;
            blank)
                echo
                ;;
        esac
    done

    [[ -n "${HELP_META[footer]:-}" ]] && echo -e "\n  ${NOTE_CLR}${HELP_META[footer]}${RST}"
    echo

    menu_exit 0
}

# =============================================================================
#  render_menu  — Despacha argumentos según MENU_ROUTES
#
#  MENU_ROUTES   – [flag]="funcion [N]"   N = args extra requeridos tras el flag
#  MENU_REQUIRE_ROOT     – "true"|"false"  (defecto: false)
#  MENU_HELP_ON_EMPTY    – "true"|"false"  (defecto: true)
#  MENU_SHOW_DONE        – "true"|"false"  (defecto: false)
#  MENU_DEBUG            – "true"|"false"  (defecto: false)
# =============================================================================
function render_menu() {
    # ── Root check ────────────────────────────────────────────────────────────
    if [[ "${MENU_REQUIRE_ROOT:-false}" == "true" && "$(id -u)" != "0" ]]; then
        lg_prt "r" "[✖] Es necesario tener permisos ROOT"
        menu_exit 1
        return 1
    fi

    # ── Sin argumentos ────────────────────────────────────────────────────────
    if [[ $# -eq 0 ]]; then
        if [[ "${MENU_HELP_ON_EMPTY:-true}" == "true" ]]; then
            render_help
        fi
        menu_exit 0
        return 0
    fi

    local flag="$1"
    shift   # $@ ahora son los argumentos TRAS el flag — se pasan íntegros al handler

    # ── Debug ─────────────────────────────────────────────────────────────────
    if [[ "${MENU_DEBUG:-false}" == "true" ]]; then
        lg_prt "cy" "[DEBUG] flag:" "$flag"
        lg_prt "cy" "[DEBUG] args:" "$*"
    fi

    # ── Resolver ruta ─────────────────────────────────────────────────────────
    local route=""
    if [[ -n "${MENU_ROUTES[$flag]+_}" ]]; then
        route="${MENU_ROUTES[$flag]}"
    elif [[ -n "${MENU_ROUTES["*"]+_}" ]]; then
        route="${MENU_ROUTES["*"]}"
        # El catch-all recibe el flag también como primer argumento
        set -- "$flag" "$@"
    else
        route="render_help"
    fi

    # ── Extraer función y args requeridos ─────────────────────────────────────
    local func required_args
    read -r func required_args <<< "$route"
    required_args="${required_args:-0}"

    # ── Validar args requeridos ───────────────────────────────────────────────
    if [[ "$required_args" -gt 0 && $# -lt "$required_args" ]]; then
        lg_prt "ry" "[✖] Parámetros insuficientes para '$flag'" "Usa --help"
        menu_exit 1
        return 1
    fi

    # ── Verificar que la función existe ───────────────────────────────────────
    if ! declare -f "$func" &>/dev/null; then
        lg_prt "r" "[✖] Función no encontrada: $func"
        menu_exit 1
        return 1
    fi

    [[ "${MENU_DEBUG:-false}" == "true" ]] && lg_prt "cy" "[DEBUG] → $func $*"

    # ── Ejecutar ──────────────────────────────────────────────────────────────
    "$func" "$@"
    local rc=$?

    if [[ "${MENU_SHOW_DONE:-false}" == "true" && $rc -eq 0 ]]; then
        lg_prt "g" "[✔] Tarea finalizada"
    fi

    menu_exit $rc
    return $rc
}
