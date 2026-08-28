#!/usr/bin/env bash
# Инициализация нового корня проекта из шаблона.
# init.sh <ИМЯ> <ПРЕФИКС-ЗАДАЧ> <целевая-папка>   напр.: init.sh myshop MYS ~/Projects/myshop
# Если целевая папка уже существует (миграция существующего проекта) — файлы, которые уже есть, НЕ перезаписываются,
# список пропущенных печатается; см. MIGRATION.md.
set -euo pipefail
[[ $# -eq 3 ]] || { sed -n 2,5p "$0"; exit 2; }
NAME="$1"; PREFIX="$2"; DST="$3"; SRC="$(cd "$(dirname "$0")/skeleton" && pwd)"
mkdir -p "$DST"; skipped=()
while IFS= read -r -d '' f; do
  rel="${f#$SRC/}"; rel="${rel/#_claude\//.claude/}"; out="$DST/$rel"   # skeleton/_claude → .claude (чтобы шаблон не подхватывался как конфиг)
  if [[ -e "$out" ]]; then skipped+=("$rel"); continue; fi
  mkdir -p "$(dirname "$out")"
  case "$f" in *.sh|*.py) sed -e "s/{{PROJECT}}/$NAME/g" -e "s/{{TASK_PREFIX}}/$PREFIX/g" "$f" > "$out"; chmod +x "$out";;
    *) sed -e "s/{{PROJECT}}/$NAME/g" -e "s/{{TASK_PREFIX}}/$PREFIX/g" "$f" > "$out";; esac
done < <(find "$SRC" -type f -print0)
cd "$DST"; [[ -d .git ]] || { git init -q; echo "git init: $DST"; }
echo "готово: $DST"; [[ ${#skipped[@]} -gt 0 ]] && { echo "пропущено (уже есть):"; printf '  %s\n' "${skipped[@]}"; }
echo "дальше: склонируй репо сервисов, затем в Claude Code из корня: «прочитай agent-workspace-template/SEED.md и выполни» (или /seed)"
