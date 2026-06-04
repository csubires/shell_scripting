#!/bin/bash

# check-git-repos.sh - Verifica repositorios git con cambios pendientes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST_FILE="${1:-listado.list}"
REPO_LIST_FILE="$SCRIPT_DIR/$LIST_FILE"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funciones de logging
log() {
    echo -e "${GREEN}[+]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[-]${NC} $1"
}

info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Verificar si el archivo listado.list existe
check_list_file() {
    if [[ ! -f "$REPO_LIST_FILE" ]]; then
        error "Archivo $REPO_LIST_FILE no encontrado"
        echo ""
        echo "Crear un archivo 'listado.list' con rutas a repositorios git:"
        echo "  /ruta/al/repo1"
        echo "  /ruta/al/repo2"
        echo "  /ruta/al/repo3"
        echo ""
        echo "O especificar otro archivo: $0 <archivo_listado>"
        exit 1
    fi
}

# Verificar estado de un repositorio git
check_repo_status() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    
    echo -e "\n${CYAN}=== Verificando: $repo_name ===${NC}"
    echo "Ruta: $repo_path"
    
    # Verificar si es un directorio válido
    if [[ ! -d "$repo_path" ]]; then
        error "  ❌ No existe o no es un directorio"
        return 1
    fi
    
    # Verificar si es un repositorio git
    if [[ ! -d "$repo_path/.git" ]]; then
        error "  ❌ No es un repositorio git"
        return 1
    fi
    
    cd "$repo_path" || return 1
    
    # Obtener información del repositorio
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null)
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null)
    
    echo "  📋 Rama: $current_branch"
    echo "  🌐 Remote: ${remote_url:-N/A}"
    
    local has_changes=0
    local changes_details=()
    
    # Verificar cambios sin stage
    local unstaged_changes
    unstaged_changes=$(git status --porcelain 2>/dev/null | grep -E '^\s*[MARCD]' | wc -l)
    if [[ $unstaged_changes -gt 0 ]]; then
        changes_details+=("$unstaged_changes archivos modificados")
        has_changes=1
    fi
    
    # Verificar cambios staged
    local staged_changes
    staged_changes=$(git status --porcelain 2>/dev/null | grep -E '^[MARCD]' | wc -l)
    if [[ $staged_changes -gt 0 ]]; then
        changes_details+=("$staged_changes archivos staged")
        has_changes=1
    fi
    
    # Verificar commits sin pushear
    local unpushed_commits
    unpushed_commits=$(git log --oneline origin/"$current_branch".."$current_branch" 2>/dev/null | wc -l)
    if [[ $unpushed_commits -gt 0 ]]; then
        changes_details+=("$unpushed_commits commits sin pushear")
        has_changes=1
    fi
    
    # Verificar archivos sin track
    local untracked_files
    untracked_files=$(git status --porcelain 2>/dev/null | grep -E '^\?\?' | wc -l)
    if [[ $untracked_files -gt 0 ]]; then
        changes_details+=("$untracked_files archivos sin track")
        has_changes=1
    fi
    
    if [[ $has_changes -eq 1 ]]; then
        warn "  ⚠️  CAMBIOS PENDIENTES:"
        for detail in "${changes_details[@]}"; do
            echo "     • $detail"
        done
        
        # Mostrar resumen de cambios
        echo ""
        echo "  📊 Resumen de cambios:"
        git status --short 2>/dev/null | head -10
        if [[ $(git status --short 2>/dev/null | wc -l) -gt 10 ]]; then
            echo "     ... y más"
        fi
        return 0
    else
        log "  ✅ Limpio - Sin cambios pendientes"
        return 2
    fi
}

# Función principal
main() {
    echo -e "${BLUE}🔍 Verificador de Repositorios Git${NC}"
    echo "=========================================="
    
    check_list_file
    
    local total_repos=0
    local dirty_repos=0
    local clean_repos=0
    local error_repos=0
    
    # Leer el archivo de listado
    while IFS= read -r repo_path || [[ -n "$repo_path" ]]; do
        # Saltar líneas vacías y comentarios
        [[ -z "$repo_path" || "$repo_path" =~ ^[[:space:]]*# ]] && continue
        
        # Expandir ~ en rutas
        repo_path="${repo_path/#\~/$HOME}"
        
        ((total_repos++))
        
        case $(check_repo_status "$repo_path"; echo $?) in
            0) ((dirty_repos++)) ;;
            2) ((clean_repos++)) ;;
            *) ((error_repos++)) ;;
        esac
        
    done < "$REPO_LIST_FILE"
    
    # Resumen final
    echo -e "\n${CYAN}==========================================${NC}"
    echo -e "${BLUE}📊 RESUMEN FINAL:${NC}"
    echo "   Total repositorios: $total_repos"
    echo -e "   ${GREEN}✅ Limpios: $clean_repos${NC}"
    echo -e "   ${YELLOW}⚠️  Con cambios: $dirty_repos${NC}"
    echo -e "   ${RED}❌ Con errores: $error_repos${NC}"
    echo -e "${CYAN}==========================================${NC}"
}

# Ejecutar función principal
main "$@"
