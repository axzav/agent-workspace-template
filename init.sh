#!/usr/bin/env bash
# Инициализация нового корня проекта из шаблона.
# init.sh <ИМЯ> <ПРЕФИКС-ЗАДАЧ> <целевая-папка> [local|remote]   напр.: init.sh myshop MYS ~/Projects/myshop remote
# Режим трекера (по умолчанию local) записывается в project.yaml и выбирает набор команд .claude/commands + prompts:
# в local-режиме команды удалённого трекера (REMOTE_ONLY ниже) не ставятся. Добавить позже: init.sh … remote
# (существующие файлы не перезаписываются, докладываются только недостающие).
# Если целевая папка уже существует (миграция существующего проекта) — файлы, которые уже есть, НЕ перезаписываются,
# список пропущенных печатается; см. MIGRATION.md.
set -euo pipefail
[[ $# -eq 3 || $# -eq 4 ]] || { sed -n 2,8p "$0"; exit 2; }
NAME="$1"; PREFIX="$2"; DST="$3"; MODE="${4:-local}"; SRC="$(cd "$(dirname "$0")/skeleton" && pwd)"
[[ "$MODE" == local || "$MODE" == remote ]] || { echo "режим: local | remote"; exit 2; }
REMOTE_ONLY="task tracker-pull tracker-comment task-description fix-mr"   # команды, нужные только с удалённым трекером
mkdir -p "$DST"; skipped=(); profiled=()
while IFS= read -r -d '' f; do
  rel="${f#$SRC/}"; rel="${rel/#_claude\//.claude/}"; out="$DST/$rel"   # skeleton/_claude → .claude (чтобы шаблон не подхватывался как конфиг)
  case "$rel" in .claude/commands/*.md|workspace/prompts/*.md)
    n="$(basename "$rel" .md)"; [[ "$MODE" == local && " $REMOTE_ONLY " == *" $n "* ]] && { profiled+=("$rel"); continue; };; esac
  if [[ -e "$out" ]]; then skipped+=("$rel"); continue; fi
  mkdir -p "$(dirname "$out")"
  sed -e "s/{{PROJECT}}/$NAME/g" -e "s/{{TASK_PREFIX}}/$PREFIX/g" -e "s/{{TRACKER_MODE}}/$MODE/g" "$f" > "$out"
  case "$f" in *.sh|*.py) chmod +x "$out";; esac
done < <(find "$SRC" -type f -print0)
cd "$DST"; [[ -d .git ]] || { git init -q; echo "git init: $DST"; }
echo "готово: $DST (трекер: $MODE)"
[[ ${#profiled[@]} -gt 0 ]] && { echo "не поставлено (только для remote-режима):"; printf '  %s\n' "${profiled[@]}"; }
[[ ${#skipped[@]} -gt 0 ]] && { echo "пропущено (уже есть):"; printf '  %s\n' "${skipped[@]}"; }
echo "дальше: склонируй репо сервисов (или, если их ещё нет, положи концепт-доки в workspace/docs/), затем в Claude Code из корня: «прочитай agent-workspace-template/SEED.md и выполни» (или /seed)"
