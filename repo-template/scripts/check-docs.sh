#!/usr/bin/env bash
# Гейт техдоков репо (запускать из корня репо или из любого места; шаг в CI/локальном прогоне).
# 1. Ссылки: относительный путь в бэктиках внутри AGENTS.md и docs/*.md должен существовать (короткая форма не проходит);
#    пути за пределы репо пропускаются — у того, кто клонировал только репо, личного слоя нет.
# 2. Свежесть: изменился файл из третьего столбца карты docs/README.md — техдок темы правлен в том же диапазоне
#    ($BASE..HEAD плюс рабочее дерево; BASE: $CI_BASE, иначе merge-base с $BASE_BRANCH на ветке, иначе HEAD~1).
#    Предупреждение вместо ошибки — CHECK_DOCS=warn (чистый рефакторинг без смены контракта — сказать в отчёте).
set -euo pipefail
cd "$(dirname "$0")/.."
BASE_BRANCH="${BASE_BRANCH:-main}"
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)
if [[ -n "${CI_BASE:-}" ]]; then base=$CI_BASE
elif [[ "$branch" != "$BASE_BRANCH" && "$branch" != "HEAD" ]] && git rev-parse -q --verify "$BASE_BRANCH" >/dev/null; then base=$(git merge-base "$BASE_BRANCH" HEAD)
else base=$(git rev-parse -q --verify HEAD~1 || git rev-parse HEAD); fi

skip="${CHECK_DOCS_SKIP:-}"   # файлы, которых ещё нет (анонсированы в карте): CHECK_DOCS_SKIP="saves.md mod-api.md"
lrc=0
for f in AGENTS.md docs/*.md; do
  [[ -f "$f" ]] || continue
  depth=$(tr -cd '/' <<<"$f" | wc -c)
  for p in $(grep -oE '`\.{0,2}[A-Za-z0-9_./-]*\.md`|`\.\.?/[A-Za-z0-9_./-]+/`' "$f" | tr -d '`' | sort -u); do
    [[ " $skip " == *" $p "* || "$p" == *'{{'* ]] && continue
    up=0; rest=$p; while [[ $rest == ../* ]]; do up=$((up + 1)); rest=${rest#../}; done
    (( up > depth )) && continue
    [[ -e "$(dirname "$f")/$p" ]] || { echo "✖ ссылка: $f → нет $p"; lrc=1; }
  done
done
[[ $lrc -eq 0 ]] && echo "✔ docs: ссылки целы" || { echo "✖ docs: битые ссылки выше"; exit 1; }

changed=$( { git diff --name-only "$base" HEAD; git diff --name-only HEAD; git ls-files --others --exclude-standard; } | sort -u)
[[ -n "$changed" ]] || { echo "✔ docs: изменений нет"; exit 0; }

# Карта «код → техдок» — третий столбец таблицы docs/README.md; `\|` в regex — экранированный разделитель ячейки.
map=docs/README.md
rules=$(awk '/^\| `[a-z-]+\.md` \|/ {
          n = split($0, c, / \| /); if (n < 3) next
          doc = c[1]; re = c[n]
          gsub(/^\| *`|` *$/, "", doc); sub(/ *\| *$/, "", re); gsub(/^ *`|` *$/, "", re); gsub(/\\\|/, "|", re)
          if (re == "—" || re == "" || re ~ /\{\{/) next
          print re "\t" "docs/" doc }' "$map")
[[ -n "$rules" ]] || { echo "✔ docs: в карте $map нет триггеров"; exit 0; }
rc=0
while IFS=$'\t' read -r re doc; do
  [[ -n "$re" ]] || continue
  hits=$(grep -E "^($re)" <<<"$changed" || true)
  [[ -n "$hits" ]] || continue
  if grep -qx "$doc" <<<"$changed"; then echo "✔ $doc правлен вместе с: $(echo "$hits" | tr '\n' ' ')"
  else echo "✖ $doc не тронут, а изменились: $(echo "$hits" | tr '\n' ' ')"; rc=1; fi
done <<<"$rules"
if [[ $rc -ne 0 && "${CHECK_DOCS:-fail}" == "warn" ]]; then echo "⚠ docs: расхождения выше — предупреждение (CHECK_DOCS=warn)"; exit 0; fi
[[ $rc -eq 0 ]] && echo "✔ docs: техдоки тем правлены вместе с кодом" || echo "✖ docs: правь техдок темы (карта — docs/README.md) в этом же изменении или CHECK_DOCS=warn с причиной в отчёте"
exit $rc
