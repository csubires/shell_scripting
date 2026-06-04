#!/usr/bin/env bash
# =============================================================================
#  aliashelp.sh – Help menu interactivo para ~/.aliasrc.zsh
#  Uso: bash aliashelp.sh [seccion]
#  Secciones: nav | sys | vim | util | app | clip | git | func | ext
# =============================================================================

# ── Paleta de colores ─────────────────────────────────────────────────────────
declare -A PALETTE=(
    [x]='\033[0m'           # reset
    [n]='\033[1m'           # bold
    [w]='\033[97m'          # white
    [g]='\033[92m'          # green
    [y]='\033[93m'          # yellow
    [b]='\033[94m'          # blue
    [c]='\033[96m'          # cyan
    [v]='\033[95m'          # magenta/violet
    [o]='\033[33m'          # orange/dark yellow
    [r]='\033[91m'          # red
)

# ── Metadatos ─────────────────────────────────────────────────────────────────
declare -A HELP_META
declare -a HELP_OPTIONS

SECTION="${1:-all}"

HELP_META[title]="Alias & Functions Reference  ~/.aliasrc.zsh"
HELP_META[script]="aliashelp.sh"
HELP_META[usage]="[nav|sys|vim|util|app|clip|git|func|ext|all]"
HELP_META[footer]="Editar aliases: rcali  ·  Recargar zsh: rezsh  ·  Source: ~/.aliasrc.zsh"
HELP_SEP="|"

# =============================================================================
#  Secciones de ayuda
# =============================================================================

section_nav() {
    HELP_OPTIONS+=(
        "section|NAVEGACIÓN – Directorios y CD"
        "option|1 … 9                   |Subir N niveles de directorio            |cd ../../.. (3 niveles)"
        "option|cdmk <dir>              |Crear directorio y entrar en él"
        "option|cdmktmp                 |Crear directorio temporal y entrar"
        "option|cdfzf                   |Navegar directorios con FZF interactivo"
        "blank|"
        "option|cdgit                   |Ir a ~/Documents/GIT"
        "option|cdbox                   |Ir a ~/Documents/box"
        "option|cdscr                   |Ir a ~/Documents/Scripts"
        "option|cdpro                   |Ir a ~/Documents/Projects"
        "option|cdrep                   |Ir a ~/Documents/Repository"
        "option|cdext                   |Ir a /mnt/hgfs (VM shared folder)"
        "option|cdtmp                   |Ir a /tmp"
        "option|cdocs                   |Ir a ~/Documents"
        "blank|"
        "example|cdfzf                  |Abre FZF con preview tree para elegir dir"
        "example|cdmk proyectos/nuevo   |mkdir -p + cd en un solo comando"
        "example|3                      |Equivale a: cd ../../.."
    )
}

section_sys() {
    HELP_OPTIONS+=(
        "section|SISTEMA – Comandos base"
        "option|_  <cmd>                |Ejecutar comando como sudo              |alias de: sudo"
        "option|ls                      |Listado con colores"
        "option|ll                      |Listado largo con permisos y tamaños"
        "option|la                      |Listado largo incluyendo ocultos"
        "option|lc                      |Listar solo directorios con ruta absoluta"
        "option|latr                    |Listado largo ordenado por fecha (más viejo primero)"
        "option|rezsh                   |Recargar configuración de zsh"
        "option|fd <patrón>             |Buscar archivos (fdfind con colores)     |más rápido que find"
        "blank|"
        "option|.net                    |Mostrar conexiones de red activas        |ss -tupan"
        "option|.cnx                    |Listar archivos abiertos en red          |lsof -i"
        "option|.fop                    |Archivos abiertos por el usuario actual  |lsof -u \$USER"
        "option|.grep <str>             |grep recursivo, insensible, con color    |-rniI"
        "option|.find <nombre>          |find en directorio actual (insensible)   |find . -iname"
        "option|.tree                   |tree con colores                         |tree -C"
        "option|.demo                   |Servicios systemd en ejecución           |top 20"
        "option|.memo                   |Procesos ordenados por uso de RAM        |top 15"
        "option|.cpup                   |Procesos ordenados por uso de CPU        |top 15"
        "option|.pwd <n>                |Generar contraseña aleatoria base64      |openssl rand -base64 N"
        "option|.kpwd                   |Generar contraseña de 32 bytes base64    |segura para claves"
        "option|msize                   |Tamaño del directorio actual             |du -hc ."
        "blank|"
        "example|_ apt update           |sudo apt update"
        "example|.grep 'TODO' .         |grep -rniI --color=auto 'TODO' ."
        "example|.pwd 16                |Genera password aleatoria de 16 bytes"
        "example|.memo                  |Ver qué proceso consume más RAM"
    )
}

section_vim() {
    HELP_OPTIONS+=(
        "section|VIM / CONFIGURACIÓN – Edición rápida de configs"
        "option|vi                      |Abrir vim"
        "option|rczsh                   |Editar ~/.zshrc con vim"
        "option|rcali                   |Editar ~/.aliasrc.zsh con vim"
        "option|rcvim                   |Editar ~/.vimrc con vim"
        "option|rckit                   |Editar ~/.config/kitty/kitty.conf"
        "option|rcnft                   |Editar /etc/nftables.conf (sudo)"
        "option|vimtmp                  |Crear fichero temporal en /tmp y abrir en vim"
        "blank|"
        "example|rcali                  |Abre el fichero de aliases en vim"
        "example|vimtmp                 |Crea temp_1234567890.txt, abre vim, copia nombre al clipboard"
    )
}

section_util() {
    HELP_OPTIONS+=(
        "section|UTILIDADES – Herramientas del día a día"
        "option|.bat <file>             |Ver fichero con sintaxis resaltada       |batcat"
        "option|blame                   |Ver tiempo de arranque por servicio      |systemd-analyze blame"
        "option|rmtr <file>             |Mover a papelera en vez de borrar        |trash-put"
        "option|msto <servicio>         |Reiniciar servicio systemd               |sudo systemctl restart"
        "option|mres <servicio>         |Parar servicio systemd                   |sudo systemctl stop"
        "option|md2pdf <file.md>        |Convertir Markdown a PDF                 |pandoc + plantilla eisvogel"
        "option|backupf <file>          |Backup de fichero con timestamp          |copia a file.bak.YYYY-MM-DD"
        "option|secrm <file>            |Borrado seguro con confirmación          |shred -u -v -z"
        "option|myip                    |Mostrar IP pública actual                |curl ipinfo.io/ip"
        "blank|"
        "example|msto nginx             |sudo systemctl restart nginx"
        "example|mres ssh               |sudo systemctl stop ssh"
        "example|md2pdf informe.md      |Genera informe.pdf con eisvogel"
        "example|backupf sshd_config    |Crea sshd_config.bak.2025-01-15_10:30:00"
        "example|secrm secreto.txt      |Pide confirmación y hace shred del fichero"
    )
}

section_app() {
    HELP_OPTIONS+=(
        "section|APLICACIONES – Lanzadores"
        "option|code                    |Abrir VSCode (Flatpak)"
        "option|sublime                 |Abrir Sublime Text"
        "option|runkitty                |Ejecutar script de arranque de Kitty     |~/Documents/Scripts/run_kitty.sh"
        "option|todep                   |Script de dependencias                   |~/Documents/Scripts/todep/todep.sh"
        "option|syslog                  |Script de análisis de syslog             |~/Documents/Scripts/syslog.sh"
        "option|formatcpp               |Formatear ficheros C++                   |~/Documents/Scripts/format_cpp.sh"
        "option|formatpython            |Formatear ficheros Python                |~/Documents/Scripts/format_py.sh"
    )
}

section_clip() {
    HELP_OPTIONS+=(
        "section|CLIPBOARD – Copiar y pegar con xclip"
        "option|c                       |Copiar stdin al clipboard (Ctrl+C)       |xclip -selection clipboard"
        "option|v                       |Pegar desde clipboard                    |xclip -selection clipboard -o"
        "option|pc                      |Copiar al clipboard primario             |xclip -selection primary"
        "option|pp                      |Pegar desde clipboard primario"
        "option|cpwd                    |Copiar ruta actual al clipboard          |pwd | xclip"
        "option|texto <texto>           |Copiar texto arbitrario al clipboard"
        "option|ccmd                    |Sin args: copia último comando al clip   |Con args: ejecuta y copia resultado"
        "blank|"
        "example|ls -la | c             |Copia la salida de ls al clipboard"
        "example|v                      |Pega lo que hay en el clipboard"
        "example|cpwd                   |Copia /home/user/proyectos al clipboard"
        "example|texto 'hola mundo'     |Copia 'hola mundo' al clipboard"
        "example|ccmd                   |Copia el último comando ejecutado"
        "example|ccmd ls -la            |Ejecuta ls -la y copia el resultado"
    )
}

section_git() {
    HELP_OPTIONS+=(
        "section|GIT – Log, stats y blame"
        "option|glog                    |Log compacto: grafo + ramas + 15 commits |--oneline --graph --decorate"
        "option|glogd                   |Log detallado: hash, fecha, autor        |formato coloreado, 10 commits"
        "option|gstats                  |Commits por autor en todas las ramas     |git shortlog -sn --all"
        "option|gblame <ext>            |Blame por extensión de fichero           |busca *.ext y muestra autores"
        "option|meval                   |Arrancar ssh-agent y añadir clave git    |ssh-add darkc_git_ed25519"
        "blank|"
        "example|glog                   |Vista rápida del historial con ramas"
        "example|glogd                  |Historial detallado con fechas relativas"
        "example|gstats                 |Ver quién ha hecho más commits"
        "example|gblame py              |Ver autores de todos los ficheros .py"
        "example|meval                  |Activar ssh-agent para push/pull por SSH"
    )
}

section_func() {
    HELP_OPTIONS+=(
        "section|FUNCIONES FZF – Búsqueda interactiva"
        "option|cdfzf                   |CD interactivo con FZF + preview tree"
        "option|fzfpv                   |Buscar fichero con preview bat           |find + fzf + batcat"
        "option|fzfvi                   |Buscar fichero con FZF y abrir en vim"
        "option|fzfhi [término]         |Historial interactivo FZF + ejecutar     |con/sin filtro de búsqueda"
        "option|fzfgr <string>          |Grep recursivo + selección FZF           |preview con línea resaltada"
        "option|fzfname <patrón>        |Buscar fichero por nombre + FZF          |preview con bat"
        "blank|"
        "section|FUNCIONES HISTORIAL"
        "option|mhist [término] [N]     |Últimos N comandos del historial         |default N=30, coloreado"
        "blank|"
        "section|FUNCIONES FZF ENV"
        "option|FZF_DEFAULT_COMMAND     |fd --hidden, excluye .git               |comando base de FZF"
        "option|FZF_CTRL_T_COMMAND      |Igual que DEFAULT                        |Ctrl+T busca ficheros"
        "option|FZF_ALT_C_COMMAND       |fd solo directorios                      |Alt+C navega dirs"
        "blank|"
        "example|fzfpv                  |Abre buscador de ficheros con preview"
        "example|fzfgr 'TODO'           |Busca 'TODO' en todos los ficheros, selección interactiva"
        "example|fzfname '.sh'          |Busca ficheros que contengan .sh en el nombre"
        "example|fzfhi docker           |Filtra historial por 'docker', elige y ejecuta"
        "example|mhist git 20           |Últimos 20 comandos que contienen 'git'"
        "example|fzfvi                  |Elige fichero con FZF y lo abre en vim"
    )
}

section_ext() {
    HELP_OPTIONS+=(
        "section|SCRIPTS EXTERNOS – Rutas rápidas"
        "option|todep                   |Gestión de dependencias del proyecto     |~/Documents/Scripts/todep/todep.sh"
        "option|syslog                  |Análisis de logs del sistema             |~/Documents/Scripts/syslog.sh"
        "option|formatcpp               |Formatear código C++ automáticamente     |~/Documents/Scripts/format_cpp.sh"
        "option|formatpython            |Formatear código Python automáticamente  |~/Documents/Scripts/format_py.sh"
        "option|runkitty                |Arrancar Kitty terminal                  |~/Documents/Scripts/run_kitty.sh"
        "blank|"
        "section|CONSTANTES / PATHS (comentadas, activar si se necesitan)"
        "option|PYTHONPATH              |Añadir módulos propios a Python          |~/Documents/Projects/modules"
        "option|cursus                  |Ir a ~/Documents/GIT/cursus              |proyectos 42"
        "option|help42                  |Ir a ~/Documents/GIT/help                |recursos 42"
    )
}

# =============================================================================
#  render_help – tu función original sin tocar
# =============================================================================
render_help() {
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
    printf '\033[H\033[2J\033[3J'
    local title="${HELP_META[title]:-Help}"
    echo -e "\n  ${TITLE_CLR}━━━  ${title}  ━━━${RST}\n"
    local script="${HELP_META[script]:-./script.sh}"
    local usage="${HELP_META[usage]:-}"
    echo -e "  ${LABEL_CLR}Uso:${RST}  ${SECTION_CLR}${script}${RST}  ${DESC_CLR}${usage}${RST}\n"
    local line type f1 f2 f3
    for line in "${HELP_OPTIONS[@]}"; do
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
    if [[ -n "${HELP_META[footer]:-}" ]]; then
        echo -e "\n  ${NOTE_CLR}${HELP_META[footer]}${RST}"
    fi
    echo
    exit 0
}

# =============================================================================
#  Construcción del menú según sección solicitada
# =============================================================================
case "$SECTION" in
    nav)
        HELP_META[title]="Navegación – Alias & CD"
        section_nav
        ;;
    sys)
        HELP_META[title]="Sistema – Comandos base"
        section_sys
        ;;
    vim)
        HELP_META[title]="Vim & Configs – Edición rápida"
        section_vim
        ;;
    util)
        HELP_META[title]="Utilidades – Herramientas generales"
        section_util
        ;;
    app)
        HELP_META[title]="Aplicaciones – Lanzadores"
        section_app
        ;;
    clip)
        HELP_META[title]="Clipboard – Copiar y pegar"
        section_clip
        ;;
    git)
        HELP_META[title]="Git – Log, stats y SSH"
        section_git
        ;;
    func)
        HELP_META[title]="Funciones FZF & Historial"
        section_func
        ;;
    ext)
        HELP_META[title]="Scripts externos & Paths"
        section_ext
        ;;
    all|*)
        section_nav
        section_sys
        section_vim
        section_util
        section_app
        section_clip
        section_git
        section_func
        section_ext
        ;;
esac

render_help
