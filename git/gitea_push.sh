#!/usr/bin/env bash
# gitea_push.sh - Push all local repos to gitea with credentials
set -uo pipefail

JSON_FILE="${1:-repos.json}"
GITEA_USER="csubires"
GITEA_PASS="${GITEA_PASS:-}"

if [[ -z "$GITEA_PASS" ]]; then
  read -rsp "Gitea password: " GITEA_PASS
  echo ""
fi

if [[ ! -f "$JSON_FILE" ]]; then
  echo "Error: JSON file not found: $JSON_FILE"
  exit 1
fi

# Script temporal que responde las preguntas de credenciales de git
ASKPASS_SCRIPT=$(mktemp /tmp/gitea_askpass.XXXXXX)
cat > "$ASKPASS_SCRIPT" <<EOF
#!/usr/bin/env bash
case "\$1" in
  *Username*) echo "${GITEA_USER}" ;;
  *Password*) echo "${GITEA_PASS}" ;;
esac
EOF
chmod +x "$ASKPASS_SCRIPT"
export GIT_ASKPASS="$ASKPASS_SCRIPT"
export GIT_TERMINAL_PROMPT=0

# Limpiar al salir
trap 'rm -f "$ASKPASS_SCRIPT"' EXIT

mapfile -t LOCALS < <(jq -r '.[] | select(.local != "") | .local' "$JSON_FILE")
mapfile -t NAMES  < <(jq -r '.[] | select(.local != "") | .name'  "$JSON_FILE")

TOTAL=${#LOCALS[@]}
OK=0; FAIL=0; SKIP=0

echo "========================================"
echo " Gitea mirror push — $(date '+%Y-%m-%d %H:%M:%S')"
echo " Repos to process: $TOTAL"
echo "========================================"

for i in "${!LOCALS[@]}"; do
  LOCAL="${LOCALS[$i]}"
  NAME="${NAMES[$i]}"

  echo ""
  echo "── [$((i+1))/$TOTAL] $NAME"
  echo "   path: $LOCAL"

  if [[ ! -d "$LOCAL" ]]; then
    echo "   [SKIP] Directory does not exist."; (( SKIP++ )) || true; continue
  fi
  if [[ ! -d "$LOCAL/.git" ]]; then
    echo "   [SKIP] Not a git repository."; (( SKIP++ )) || true; continue
  fi
  if ! git -C "$LOCAL" remote get-url gitea &>/dev/null; then
    echo "   [SKIP] No 'gitea' remote configured."; (( SKIP++ )) || true; continue
  fi

  BRANCH=$(git -C "$LOCAL" symbolic-ref --short HEAD 2>/dev/null || echo "")
  if [[ -z "$BRANCH" ]]; then
    echo "   [SKIP] Detached HEAD."; (( SKIP++ )) || true; continue
  fi

  echo "   branch: $BRANCH"
  if git -C "$LOCAL" push -u gitea "$BRANCH" 2>&1 | sed 's/^/   /'; then
    echo "   [OK] Pushed to gitea."
    (( OK++ )) || true
  else
    echo "   [FAIL] git push failed."
    (( FAIL++ )) || true
  fi

done

echo ""
echo "========================================"
echo " Done.  OK=$OK  FAIL=$FAIL  SKIP=$SKIP"
echo "========================================"