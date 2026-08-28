#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# Копирует внешние скиллы (project.yaml: toolkit.sources — папки вида <repo>/skills от корня) в .claude/skills/<name>/,
# помечая .synced-from. Скиллы без маркера (проектные) не трогает. Удалённые в источнике — удаляет. Без симлинков.
command -v rsync >/dev/null || { fail "нужен rsync"; exit 1; }
SRC=(); while IFS= read -r s; do [[ -n "$s" ]] && SRC+=("$s"); done < <(yaml_list toolkit.sources)
[[ ${#SRC[@]} == 0 ]] && { info "toolkit.sources пуст — нечего синхронизировать"; exit 0; }
dst=.claude/skills; mkdir -p "$dst"; seen=" "
for s in "${SRC[@]}"; do
  [[ -d "$s" ]] || { warn "$s не существует (не склонирован?)"; continue; }
  for d in "$s"/*/; do n=$(basename "$d"); [[ "$n" == _* ]] && continue; [[ -f "$d/SKILL.md" ]] || continue
    rsync -a --delete --exclude '.synced-from' "$d" "$dst/$n/"; echo "$s/$n" > "$dst/$n/.synced-from"; seen="$seen$n "; done
  ok "синхронизировано из $s"
done
for d in "$dst"/*/; do [[ -d "$d" ]] || continue; n=$(basename "$d"); [[ -f "$d/.synced-from" && "$seen" != *" $n "* ]] && { rm -rf "$d"; warn "удалён $n (нет в источниках)"; }; done
info "проектных (без маркера): $(for d in "$dst"/*/; do [[ -d "$d" && ! -f "$d/.synced-from" ]] && basename "$d"; done | tr '\n' ' ')"
