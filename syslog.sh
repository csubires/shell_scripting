syslog () {
    local GREEN='\033[0;32m'
    local RED='\033[0;31m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local NC='\033[0m'

    if [ -z "$1" ]; then
        echo -e "${RED}ERROR:${NC} Usage: syslog <service|error|unit>"
        echo "Examples:"
        echo "  syslog sshd      # Logs del servicio SSH"
        echo "  syslog error     # Solo errores del sistema"
        echo "  syslog docker    # Logs de Docker"
        echo "  syslog --full    # Todos los logs (con sudo si es necesario)"
        return 1
    fi

    local FILTER="$1"

    # Detectar si necesitamos sudo para ver todos los logs
    local J_CMD="journalctl"
    if [ "$FILTER" = "--full" ] || [ "$(id -u)" -ne 0 ]; then
        if ! journalctl --no-pager -n 1 &>/dev/null; then
            echo -e "${YELLOW}NOTICE:${NC} Using sudo to access system logs..."
            J_CMD="sudo journalctl"
        fi
    fi

    case "$FILTER" in
        --full)
            $J_CMD --no-pager -b
            ;;
        error|crit|emerg|alert|warn|warning|notice|info|debug)
            echo -e "${BLUE}PRIORITY:${NC} $FILTER"
            $J_CMD --no-pager -r -p "$FILTER" -b -o short-monotonic
            ;;
        *)
            if systemctl status "$FILTER" &>/dev/null || \
               systemctl list-unit-files "$FILTER.service" &>/dev/null; then
                echo -e "${GREEN}SERVICE:${NC} $FILTER"
                $J_CMD --no-pager -u "$FILTER" -n 50 --no-tail
            else
                echo -e "${YELLOW}SEARCH:${NC} '$FILTER'"
                $J_CMD --no-pager -b -o short-monotonic | grep -i --color=always "$FILTER"
            fi
            ;;
    esac
}
