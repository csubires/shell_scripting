#!/usr/bin/env bash
# git_status_check.sh

LIST_FILE="config/git_repos.list"

current_dir=$(pwd)
changes_detected=0

while IFS= read -r repo || [[ -n "$repo" ]]; do
    # Saltar líneas vacías y comentarios
    [[ -z "$repo" || "$repo" == \#* ]] && continue

    # Expandir ~
    repo="${repo/#\~/$HOME}"
    repo_name=$(basename "$repo")

    if [[ ! -d "$repo" ]]; then
        echo "❌ $repo_name - Directorio no existe: $repo"
        continue
    fi

    if [[ -d "$repo/.git" ]]; then
        cd "$repo" || continue

        # Verificar cambios locales
        local_changes=$(git status --porcelain 2>/dev/null)

        # Verificar commits no pusheados (solo si tiene remote)
        upstream_changes=""
        if git remote >/dev/null 2>&1; then
            upstream_changes=$(git log @{u}.. 2>/dev/null)
        fi

        if [[ -n "$local_changes" || -n "$upstream_changes" ]]; then
            echo "⚠️  $repo_name - CAMBIOS PENDIENTES"
            [[ -n "$local_changes" ]] && echo "$local_changes" | head -5
            changes_detected=$((changes_detected + 1))
        else
            echo "✅ $repo_name - Actualizado"
        fi

        cd "$current_dir" || exit 1
    else
        echo "❌ $repo_name - No es un repositorio Git"
    fi
    echo "---"
done < "$LIST_FILE"

echo "✅ Revisión completada. Repositorios con cambios: $changes_detected"
