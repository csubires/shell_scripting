#!/usr/bin/env bash
# =============================================================================
#  syslog.sh — Búsqueda avanzada en logs del sistema (journalctl)
#  Requiere: color.sh, menu.sh (sourced previamente)
# =============================================================================

. utils/color.sh
. utils/menu.sh

shopt -s extglob

readonly SYSLOG_DEFAULT_LINES=50

declare -A HELP_META=(
    [title]="syslog — Visor de logs del sistema"
    [script]="syslog"
    [usage]="<filtro|flag> [opciones]"
    [footer]="Requiere journalctl. Usa sudo automáticamente si es necesario."
)

declare -a HELP_OPTIONS=(
    "section|Filtros"
    "option|<servicio>|Logs de un servicio/unit systemd"
    "option|<prioridad>|Por nivel: emerg alert crit error warn notice info debug"
    "option|\"texto libre\"|Búsqueda grep en logs del boot actual"
    "blank"
    "section|Flags principales"
    "option|--full|Todos los logs del boot actual"
    "option|--boots|Listar boots disponibles"
    "blank"
    "section|Opciones combinables"
    "option|--boot <offset>|Boot específico (ej: --boot -1)|ver --boots"
    "option|--since <tiempo>|Desde hace N tiempo (ej: '2 hours')"
    "option|--follow, -f|Modo tail -f en tiempo real"
    "option|--lines, -n <N>|Número de líneas (defecto: $SYSLOG_DEFAULT_LINES)"
    "option|--export [fichero]|Guardar salida a fichero"
    "blank"
    "section|Ejemplos"
    "example|syslog sshd --follow|tail en tiempo real"
    "example|syslog error --since '30 minutes'|errores recientes"
    "example|syslog docker --boot -1 --lines 200|boot anterior"
    "example|syslog nginx --export /tmp/nginx.log|guardar a fichero"
    "example|syslog \"Out of memory\" --since '1 hour'|búsqueda libre"
)

# =============================================================================
#  Punto de entrada — NO usar render_menu directamente porque hace exit
#  y mataría la shell padre al hacer source
# =============================================================================
function syslog() {
    if ! declare -f lg_prt &>/dev/null; then
        echo "ERROR: syslog.sh requiere color.sh cargado previamente." >&2
        return 1
    fi

    local flag="${1:-}"

    case "$flag" in
        ""|--help|-h)
            # render_help hace exit — ejecutar en subshell para proteger la sesión
            ( render_help )
            return 0
            ;;
        --boots)
            syslog_list_boots
            return 0
            ;;
        *)
            syslog_dispatch "$@"
            ;;
    esac
}

# =============================================================================
#  Dispatcher principal
# =============================================================================
function syslog_dispatch() {
    local filter=""
    local boot_offset=""
    local since=""
    local follow=false
    local export_file=""
    local lines="$SYSLOG_DEFAULT_LINES"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --full)
                filter="--full"
                shift
                ;;
            --boot)
                shift
                if [[ -z "$1" || ( "$1" == -* && ! "$1" =~ ^-[0-9] ) ]]; then
                    lg_prt "ry" "[✖] --boot requiere un offset" "(ej: --boot -1)"
                    return 1
                fi
                boot_offset="$1"
                shift
                ;;
            --since)
                shift
                if [[ -z "$1" ]]; then
                    lg_prt "ry" "[✖] --since requiere un valor" "(ej: --since '2 hours')"
                    return 1
                fi
                since="$1"
                shift
                ;;
            --follow|-f)
                follow=true
                shift
                ;;
            --lines|-n)
                shift
                if [[ ! "$1" =~ ^[0-9]+$ ]]; then
                    lg_prt "r" "[✖] --lines requiere un número"
                    return 1
                fi
                lines="$1"
                shift
                ;;
            --export|-e)
                shift
                export_file="${1:-syslog_$(date '+%Y%m%d_%H%M%S').log}"
                [[ "$1" =~ ^[^-] ]] && shift
                ;;
            *)
                filter="$1"
                shift
                ;;
        esac
    done

    local j_cmd
    j_cmd="$(syslog_build_cmd)"

    local boot_arg="-b"
    [[ -n "$boot_offset" ]] && boot_arg="-b $boot_offset"

    local since_arg=""
    if [[ -n "$since" ]]; then
        [[ ! "$since" =~ (ago|[0-9]{4}-|:) ]] && since="${since} ago"
        since_arg="--since=\"$since\""
        boot_arg=""
    fi

    local follow_arg=""
    $follow && follow_arg="-f"

    local redirect=""
    if [[ -n "$export_file" ]]; then
        redirect="| tee \"$export_file\""
        lg_prt "cy" "Exportando a:" "$export_file"
    fi

    case "$filter" in

        --full|"")
            lg_prt "nb" "── Todos los logs [boot actual] ──"
            eval "$j_cmd --no-pager $boot_arg $since_arg $follow_arg $redirect"
            ;;

        @(emerg|alert|crit|error|err|warn|warning|notice|info|debug))
            lg_prt "bw" "PRIORITY:" "→ $filter"
            eval "$j_cmd --no-pager -r -p \"$filter\" $boot_arg $since_arg \
                $follow_arg -o short-monotonic $redirect" |
                syslog_colorize_priority
            ;;

        *)
            if syslog_is_unit "$filter"; then
                local unit_file
                unit_file="$(systemctl show -p FragmentPath "$filter" 2>/dev/null | cut -d= -f2)"
                lg_prt "gw" "SERVICE:" "$filter"
                [[ -n "$unit_file" ]] && lg_prt "xw" "  Unit:" "$unit_file"
                lg_prt "x" "  Últimas $lines líneas"
                eval "$j_cmd --no-pager -u \"$filter\" -n \"$lines\" \
                    $boot_arg $since_arg $follow_arg \
                    -o short-precise $redirect" |
                    syslog_colorize_level
            else
                lg_prt "yw" "SEARCH:" "\"$filter\""
                local count
                count=$(eval "$j_cmd --no-pager $boot_arg $since_arg -o short-monotonic" |
                    grep -ci "$filter" 2>/dev/null || true)
                lg_prt "cw" "  Coincidencias:" "$count"
                echo
                eval "$j_cmd --no-pager $boot_arg $since_arg \
                    -o short-monotonic $redirect" |
                    grep -i --color=always "$filter"
            fi
            ;;
    esac
}

# =============================================================================
#  Funciones auxiliares
# =============================================================================

function syslog_build_cmd() {
    if [[ "$(id -u)" -eq 0 ]] || journalctl --no-pager -n 1 &>/dev/null; then
        echo "journalctl"
    else
        lg_prt "yw" "NOTICE:" "Usando sudo para acceder a logs..." >&2
        echo "sudo journalctl"
    fi
}

function syslog_is_unit() {
    local name="$1"
    systemctl status "$name" &>/dev/null && return 0
    systemctl status "${name}.service" &>/dev/null && return 0
    systemctl list-unit-files "${name}.service" --no-legend 2>/dev/null | grep -q . && return 0
    return 1
}

function syslog_list_boots() {
    lg_prt "nb" "── Boots disponibles ──"
    local j_cmd
    j_cmd="$(syslog_build_cmd)"
    eval "$j_cmd --list-boots" | while IFS= read -r line; do
        if echo "$line" | grep -q "^ *0 "; then
            lg_prt "gw" "$line" "← actual"
        else
            echo "  $line"
        fi
    done
}

function syslog_colorize_level() {
    while IFS= read -r line; do
        if echo "$line" | grep -qiE "(error|fail|fatal|crit|emerg|alert)"; then
            echo -e "${PALETTE[r]}${line}${PALETTE[x]}"
        elif echo "$line" | grep -qiE "(warn|warning)"; then
            echo -e "${PALETTE[y]}${line}${PALETTE[x]}"
        elif echo "$line" | grep -qiE "(started|active|success|ready|ok\b)"; then
            echo -e "${PALETTE[g]}${line}${PALETTE[x]}"
        else
            echo "$line"
        fi
    done
}

function syslog_colorize_priority() {
    while IFS= read -r line; do
        if echo "$line" | grep -qiE "(emerg|alert|crit)"; then
            echo -e "${PALETTE[r]}${PALETTE[n]}${line}${PALETTE[x]}"
        elif echo "$line" | grep -qiE "(error|err)"; then
            echo -e "${PALETTE[r]}${line}${PALETTE[x]}"
        elif echo "$line" | grep -qiE "warn"; then
            echo -e "${PALETTE[y]}${line}${PALETTE[x]}"
        else
            echo "$line"
        fi
    done
}

syslog "$@"
