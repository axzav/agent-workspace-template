#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# Трекер из frontmatter. board | ready | gate | check | next-id | now | publish <ID> | promote <ID>. Кроме promote — ничего не пишет.
TR="$WS_DIR/tracker"
cmd="${1:-board}"; shift || true

fm() { awk 'NR==1&&$0!="---"{exit} NR>1&&$0=="---"{exit} NR>1' "$1"; }
field() { fm "$1" | awk -v k="$2" '$0 ~ "^"k":" {sub("^"k":[ ]*",""); sub(/[ ]*#.*$/,""); gsub(/^"|"$/,""); print; exit}'; }
# items <dir>: главные файлы единиц работы верхнего уровня в dir: ID-slug.md | ID-slug/ID-slug.md
# Единица — только то, что начинается с префикса id; остальное (INDEX.md, implementation.md, context/) — контекст.
items() { local d="$1"; [[ -d "$d" ]] || return 0
  for e in "$d"/"$TASK_PREFIX"-* "$d"/"$LOCAL_PREFIX"-*; do [[ -e "$e" ]] || continue; n=$(basename "$e")
    [[ "$n" == "$(basename "$d").md" ]] && continue          # главный файл самой папки — не вложенная единица
    if [[ -f "$e" && "$n" == *.md ]]; then echo "$e"
    elif [[ -d "$e" && -f "$e/$n.md" ]]; then echo "$e/$n.md"; fi
  done; }
# главный файл папки-единицы: ID-slug/ID-slug.md
is_unit_dir_main() { [[ "$(basename "$(dirname "$1")").md" == "$(basename "$1")" ]]; }
# эпик — по frontmatter type: epic
is_epic() { [[ "$(field "$1" type)" == "epic" ]]; }
# id_prefix <id> → префикс до последнего дефиса
id_prefix() { echo "${1%-*}"; }
# все задачи (включая внутри эпиков) в tasks/ и parked/; done — в done/
all_items() { for top in "$TR/tasks" "$TR/parked" "$TR"/done/*/; do for i in $(items "${top%/}"); do echo "$i"; is_epic "$i" && is_unit_dir_main "$i" && items "$(dirname "$i")"; done; done; return 0; }
epic_of() { local d m; d=$(dirname "$1"); is_unit_dir_main "$1" && d=$(dirname "$d"); m="$d/$(basename "$d").md"; [[ -f "$m" && "$m" != "$1" ]] && is_epic "$m" && echo "$m"; return 0; }
all_ids() { for f in $(all_items); do field "$f" id; done; }
rel() { echo "${1#$PROJECT_ROOT/}"; }

case "$cmd" in
  board)
    epic_filter=""; [[ "${1:-}" == "--epic" ]] && epic_filter="$2"
    printf "%-12s %-14s %-7s %-4s %-12s %s\n" "ID" "STATUS" "PRIO" "SIZE" "EPIC" "TITLE"
    for f in $(all_items); do
      case "$f" in "$TR/done"/*) continue;; esac
      is_epic "$f" && continue
      ep=$(epic_of "$f"); eid=""; [[ -n "$ep" ]] && eid=$(field "$ep" id)
      [[ -n "$epic_filter" && "$eid" != "$epic_filter" ]] && continue
      printf "%-12s %-14s %-7s %-4s %-12s %s\n" "$(field "$f" id)" "$(field "$f" status)" "$(field "$f" priority)" "$(field "$f" size)" "$eid" "$(field "$f" title)"
    done | sort -k2,2 -k3,3
    echo; info "эпики:"; for f in $(items "$TR/tasks") $(items "$TR/parked"); do is_epic "$f" && printf "  %-12s %-14s %s\n" "$(field "$f" id)" "$(field "$f" status)" "$(field "$f" title)"; done
    exit 0
    ;;
  ready|gate)
    n=0
    for f in $(all_items); do
      case "$f" in "$TR/done"/*|"$TR/parked"/*) continue;; esac
      is_epic "$f" && continue
      [[ "$(field "$f" status)" == "todo" ]] || continue
      [[ "$(field "$f" size)" == "L" ]] && continue
      ep=$(epic_of "$f"); [[ -n "$ep" ]] && [[ "$(field "$ep" status)" =~ ^(needs-decision|parked|someday|done)$ ]] && continue
      blocked=0
      for d in $(field "$f" depends | tr -d '[],'); do
        df=$(grep -rl --include='*.md' "^id: $d\$" "$TR/tasks" "$TR/parked" 2>/dev/null | head -1)
        [[ -n "$df" && "$(field "$df" status)" != "done" ]] && blocked=1
      done
      [[ $blocked == 1 ]] && continue
      n=$((n+1)); [[ "$cmd" == "ready" ]] && printf "%-12s %-7s %-4s %s  %s\n" "$(field "$f" id)" "$(field "$f" priority)" "$(field "$f" size)" "$(field "$f" title)" "${C_DIM}$(rel "$f")${C_OFF}"
    done
    [[ "$cmd" == "gate" ]] && { [[ $n -gt 0 ]] && { ok "готовых задач: $n"; exit 0; } || { warn "брать нечего"; exit 1; }; }
    [[ $n == 0 ]] && warn "готовых задач нет"; exit 0
    ;;
  check)
    rc=0
    for f in $(all_items); do
      r=$(rel "$f"); id=$(field "$f" id); st=$(field "$f" status)
      [[ -z "$id" ]] && { fail "$r: нет id"; rc=1; continue; }
      unit=$(basename "${f%.md}")
      [[ "$unit" == "$id"* ]] || { fail "$r: имя единицы «$unit» не начинается с id $id"; rc=1; }
      pfx=$(id_prefix "$id")
      [[ "$pfx" == "$TASK_PREFIX" || "$pfx" == "$LOCAL_PREFIX" ]] || { fail "$r: префикс id «$pfx» не из project.yaml ($TASK_PREFIX / $LOCAL_PREFIX)"; rc=1; }
      ty=$(field "$f" type); [[ -z "$ty" || "$ty" =~ ^(task|epic)$ ]] || { fail "$r: type: $ty (task | epic)"; rc=1; }
      rm_=$(field "$f" remote)
      [[ -n "$rm_" && "$rm_" != "$id" ]] && { fail "$r: remote: $rm_ ≠ id (в remote-режиме id = ключ трекера)"; rc=1; }
      [[ "$TRACKER_MODE" == "remote" && "$pfx" == "$TASK_PREFIX" && -z "$rm_" ]] && { fail "$r: id с префиксом трекера, но remote: пуст — локальная задача должна быть $LOCAL_PREFIX-NNNN"; rc=1; }
      for k in title status created; do [[ -z "$(field "$f" $k)" ]] && { fail "$r: нет поля $k"; rc=1; }; done
      [[ "$st" == "done" && -z "$(field "$f" closed)" ]] && { fail "$r: status done без closed:"; rc=1; }
      if is_epic "$f"; then
        is_unit_dir_main "$f" || { fail "$r: эпик (type: epic) должен быть папкой ${id}-slug/ с файлом того же имени"; rc=1; }
        is_unit_dir_main "$f" && for sub in $(items "$(dirname "$f")"); do is_epic "$sub" && { fail "$(rel "$sub"): эпик внутри эпика"; rc=1; }; done
      else
        [[ -n "$(field "$f" epic)" ]] && warn "$r: поле epic: больше не используется — принадлежность по расположению"
        is_unit_dir_main "$f" && for sub in $(items "$(dirname "$f")"); do { fail "$(rel "$sub"): задача внутри задачи"; rc=1; }; done
      fi
      top=0; [[ -z "$(epic_of "$f")" ]] && top=1
      case "$f" in
        "$TR/tasks"/*)  [[ $top == 1 && ! "$st" =~ ^(idea|todo|in-progress|needs-decision)$ ]] && { fail "$r: статус $st на верхнем уровне tasks/ (done → done/, parked → parked/)"; rc=1; } ;;
        "$TR/parked"/*) [[ $top == 1 && ! "$st" =~ ^(parked|someday)$ ]] && { fail "$r: статус $st не для parked/"; rc=1; } ;;
        "$TR/done"/*)   [[ $top == 1 && "$st" != "done" ]] && { fail "$r: в done/ нужен status: done"; rc=1; } ;;
      esac
      [[ -n "$(field "$f" remote)" && -z "$(field "$f" remote_synced)" ]] && warn "$r: файл впереди трекера (remote_synced пуст)"
      n_body=$(awk '/^---$/{c++; next} c>=2' "$f" | wc -l | tr -d ' '); n_body=${n_body:-0}
      lim=70; is_epic "$f" && lim=80
      [[ "$n_body" -gt $((lim+20)) ]] && warn "$r: постановка $n_body строк (ориентир ≤ $lim) — реализация в implementation.md или дробить"
    done
    dups=$(all_ids | sort | uniq -d); [[ -n "$dups" ]] && { fail "дубли id: $dups"; rc=1; }
    [[ $rc == 0 ]] && ok "трекер консистентен"; exit $rc
    ;;
  now)   # реальное время для frontmatter (created/closed/remote_synced) — не угадывать, а брать отсюда
    date '+%Y-%m-%d %H:%M'
    ;;
  publish)   # текст описания для удалённого трекера: publish <ID> [--json|--diff]
    id="${1:?usage: trk.sh publish <ID> [--json|--diff]}"; shift || true
    f=$(grep -rl --include='*.md' "^id: $id\$" "$TR/tasks" "$TR/parked" "$TR/done" 2>/dev/null | head -1)
    [[ -n "$f" ]] || { fail "задача $id не найдена"; exit 1; }
    python3 "$(dirname "${BASH_SOURCE[0]}")/normalize.py" "$f" "$@"
    ;;
  next-id)   # следующий id локальной задачи; в remote-режиме ключи задач трекера выдаёт сам трекер
    p="$TASK_PREFIX"; [[ "$TRACKER_MODE" == "remote" ]] && p="$LOCAL_PREFIX"
    max=$(all_ids | grep -E "^$p-[0-9]+$" | sed "s/^$p-//" | sort -n | tail -1)
    printf "%s-%04d\n" "$p" $(( 10#${max:-0} + 1 ))
    ;;
  promote)
    id="${1:?usage: trk.sh promote <ID>}"
    f=$(grep -rl --include='*.md' "^id: $id\$" "$TR/tasks" "$TR/parked" 2>/dev/null | head -1)
    [[ -n "$f" ]] || { fail "задача $id не найдена"; exit 1; }
    is_unit_dir_main "$f" && { warn "$id уже папка"; exit 0; }
    d="${f%.md}"; n=$(basename "$f"); mkdir "$d"; git mv "$f" "$d/$n" 2>/dev/null || mv "$f" "$d/$n"; ok "$(rel "$d")/$n — добавляй контекст рядом"
    ;;
  *) echo "usage: trk.sh board [--epic ID] | ready | gate | check | next-id | now | publish <ID> [--json|--diff] | promote <ID>"; exit 2 ;;
esac
