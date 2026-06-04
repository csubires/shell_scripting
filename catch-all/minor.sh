#!/bin/bash
# git-status-check.sh

LIST_FILE="listado.list"

[[ ! -f "$LIST_FILE" ]] && echo "❌ Crea $LIST_FILE con rutas a repositorios" && exit 1

echo "🔍 Repositorios con cambios pendientes:"
echo "========================================"

while IFS= read -r repo || [[ -n "$repo" ]]; do
    [[ -z "$repo" || "$repo" == \#* ]] && continue
    
    repo="${repo/#\~/$HOME}"
    repo_name=$(basename "$repo")
    
    if [[ -d "$repo/.git" ]]; then
        cd "$repo" && \
        if [[ -n "$(git status --porcelain)" || -n "$(git log @{u}.. 2>/dev/null)" ]]; then
            echo "⚠️  $repo_name - TIENE CAMBIOS"
            git status --short 2>/dev/null | head -5
        else
            echo "✅ $repo_name - Limpio"
        fi
    else
        echo "❌ $repo_name - No es repo git"
    fi
done < "$LIST_FILE"
