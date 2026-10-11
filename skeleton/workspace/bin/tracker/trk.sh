#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# Трекер из frontmatter. board | ready | gate | check | next-id | now | promote <ID>{{#if tracker=remote}} | publish <ID>{{/if}}. Кроме promote — ничего не пишет.
TR="$WS_DIR/tracker"
cmd="${1:-board}"; shift || true

fm() { awk 'NR==1&&$0!="---"{exit} NR>1&&$0=="---"{exit} NR>1' "$1"; }
field() { fm "$1" | awk -v k="$2" '$0 ~ "^"k":" {sub("^"k":[ ]*",""); sub(/[ ]*#.*$/,""); gsub(/^"|"$/,""); print; exit}'; }
# items <dir>: главные файлы единиц работы верхнего уровня в dir: ID-slug.md | ID-slug/ID-slug.md
# Единица — только то, что начинается с префикса id; остальное (INDEX.md, implementation.md, context/) — контекст.
items() { local d="$1"; [[ -d "$d" ]] || return 0
{{#if tracker=remote}}
  for e in "$d"/"$TASK_PREFIX"-* "$d"/"$LOCAL_PREFIX"-*; do [[ -e "$e" ]] || continue; n=$(basename "$e")
{{#else}}
  for e in "$d"/"$TASK_PREFIX"-*; do [[ -e "$e" ]] || continue; n=$(basename "$e")
{{/if}}
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
# все задачи (включая внутри эпиков) в tasks/ и parked/; done и cancelled — в done/
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
    n=0; held=()   # todo, которые ready пропустил: "id|size|почему" — печатаются, когда брать нечего
    for f in $(all_items); do
      case "$f" in "$TR/done"/*|"$TR/parked"/*) continue;; esac
      is_epic "$f" && continue
      [[ "$(field "$f" status)" == "todo" ]] || continue
      id=$(field "$f" id); sz=$(field "$f" size)
      [[ "$sz" == "L" ]] && { held+=("$id|$sz|размер L — дробить"); continue; }
      ep=$(epic_of "$f")
      if [[ -n "$ep" ]] && [[ "$(field "$ep" status)" =~ ^(needs-decision|parked|someday|done|cancelled)$ ]]; then
        held+=("$id|$sz|эпик $(field "$ep" id): $(field "$ep" status)"); continue; fi
      waits=""
      for d in $(field "$f" depends | tr -d '[],'); do
        if [[ "$d" == ADR-* ]]; then   # решение: блокирует, пока ADR не accepted
          af=$(grep -l --include='*.md' "^id: $d\$" "$ADR_DIR"/*.md 2>/dev/null | head -1 || true)
          if [[ -z "$af" ]]; then waits+=" $d (нет ADR)"
          elif [[ "$(field "$af" status)" != "accepted" ]]; then waits+=" $d ($(field "$af" status))"; fi
          continue; fi
        df=$(grep -rl --include='*.md' "^id: $d\$" "$TR/tasks" "$TR/parked" 2>/dev/null | head -1 || true)   # done/ не ищем: закрытая зависимость не блокирует
        [[ -n "$df" && ! "$(field "$df" status)" =~ ^(done|cancelled)$ ]] && waits+=" $d ($(field "$df" size), $(field "$df" status))"
      done
      [[ -n "$waits" ]] && { held+=("$id|$sz|ждёт:$waits"); continue; }
      n=$((n+1)); [[ "$cmd" == "ready" ]] && printf "%-12s %-7s %-4s %s  %s\n" "$(field "$f" id)" "$(field "$f" priority)" "$(field "$f" size)" "$(field "$f" title)" "${C_DIM}$(rel "$f")${C_OFF}"
    done
    [[ "$cmd" == "gate" ]] && { [[ $n -gt 0 ]] && { ok "готовых задач: $n"; exit 0; } || { warn "брать нечего"; exit 1; }; }
    if [[ $n == 0 ]]; then
      if [[ ${#held[@]} == 0 ]]; then warn "готовых задач нет: в todo пусто"
      else warn "готовых задач нет; держат очередь:"
        for h in "${held[@]}"; do IFS='|' read -r hid hsz hwhy <<<"$h"; printf "  %-12s %-4s %s\n" "$hid" "$hsz" "$hwhy"; done
      fi
    fi
    exit 0
    ;;
  check)
    rc=0
    for f in $(all_items); do
      r=$(rel "$f"); id=$(field "$f" id); st=$(field "$f" status)
      [[ -z "$id" ]] && { fail "$r: нет id"; rc=1; continue; }
      unit=$(basename "${f%.md}")
      [[ "$unit" == "$id"* ]] || { fail "$r: имя единицы «${unit}» не начинается с id $id"; rc=1; }
      pfx=$(id_prefix "$id")
{{#if tracker=remote}}
      [[ "$pfx" == "$TASK_PREFIX" || "$pfx" == "$LOCAL_PREFIX" ]] || { fail "$r: префикс id «${pfx}» не из project.yaml ($TASK_PREFIX / $LOCAL_PREFIX)"; rc=1; }
      rm_=$(field "$f" remote)
      [[ -n "$rm_" && "$rm_" != "$id" ]] && { fail "$r: remote: $rm_ ≠ id (id задачи = ключ трекера)"; rc=1; }
      [[ "$pfx" == "$TASK_PREFIX" && -z "$rm_" ]] && { fail "$r: id с префиксом трекера, но remote: пуст — задача без тикета должна быть $LOCAL_PREFIX-NNNN"; rc=1; }
      [[ -n "$rm_" && -z "$(field "$f" remote_synced)" ]] && warn "$r: файл впереди трекера (remote_synced пуст)"
{{#else}}
      [[ "$pfx" == "$TASK_PREFIX" ]] || { fail "$r: префикс id «${pfx}» не из project.yaml ($TASK_PREFIX)"; rc=1; }
{{/if}}
      ty=$(field "$f" type); [[ -z "$ty" || "$ty" =~ ^(task|epic)$ ]] || { fail "$r: type: $ty (task | epic)"; rc=1; }
      for k in title status created; do [[ -z "$(field "$f" $k)" ]] && { fail "$r: нет поля $k"; rc=1; }; done
      [[ -z "$st" || "$st" =~ ^(idea|todo|in-progress|needs-decision|parked|someday|done|cancelled)$ ]] || { fail "$r: status: $st — нет такого статуса"; rc=1; }
      [[ "$st" =~ ^(done|cancelled)$ && -z "$(field "$f" closed)" ]] && { fail "$r: status $st без closed:"; rc=1; }
      for d in $(field "$f" depends | tr -d '[],'); do
        # закрытая задача — история: заменённый ADR после перевода удаляется (decisions/README.md), ссылка остаётся
        if [[ "$d" == ADR-* ]]; then [[ "$st" =~ ^(done|cancelled)$ ]] || grep -lq --include='*.md' "^id: $d\$" "$ADR_DIR"/*.md 2>/dev/null || { fail "$r: depends: $d — нет такого ADR в workspace/docs/decisions/"; rc=1; }
        else df=$(grep -rl --include='*.md' "^id: $d\$" "$TR" 2>/dev/null | head -1 || true)
          if [[ -z "$df" ]]; then fail "$r: depends: $d — нет такой задачи"; rc=1
          # отменённая зависимость не блокирует ready, но зависящую задачу надо пересмотреть
          elif [[ "$(field "$df" status)" == "cancelled" && ! "$st" =~ ^(done|cancelled)$ ]]; then warn "$r: depends: $d отменена — пересмотреть задачу и убрать зависимость"; fi; fi
      done
      if is_epic "$f"; then
        is_unit_dir_main "$f" || { fail "$r: эпик (type: epic) должен быть папкой ${id}-slug/ с файлом того же имени"; rc=1; }
        is_unit_dir_main "$f" && for sub in $(items "$(dirname "$f")"); do is_epic "$sub" && { fail "$(rel "$sub"): эпик внутри эпика"; rc=1; }; done
      else
        [[ -n "$(field "$f" epic)" ]] && warn "$r: поле epic: не используется — принадлежность по расположению"
        is_unit_dir_main "$f" && for sub in $(items "$(dirname "$f")"); do { fail "$(rel "$sub"): задача внутри задачи"; rc=1; }; done
      fi
      top=0; [[ -z "$(epic_of "$f")" ]] && top=1
      case "$f" in
        "$TR/tasks"/*)  [[ $top == 1 && ! "$st" =~ ^(idea|todo|in-progress|needs-decision)$ ]] && { fail "$r: статус $st на верхнем уровне tasks/ (done и cancelled → done/, parked → parked/)"; rc=1; } ;;
        "$TR/parked"/*) [[ $top == 1 && ! "$st" =~ ^(parked|someday)$ ]] && { fail "$r: статус $st не для parked/"; rc=1; } ;;
        "$TR/done"/*)   [[ $top == 1 && ! "$st" =~ ^(done|cancelled)$ ]] && { fail "$r: в done/ нужен status: done или cancelled"; rc=1; } ;;
      esac
      case "$f" in "$TR/done"/*) ;; *)   # живая постановка — с обязательными разделами; длина не ограничена
        for s in "Контекст / Проблема" "Что делаем" "Критерии готовности"; do grep -qxF "## $s" "$f" || warn "$r: нет раздела «## ${s}»"; done ;; esac
    done
    dups=$(all_ids | sort | uniq -d); [[ -n "$dups" ]] && { fail "дубли id: $dups"; rc=1; }
    [[ $rc == 0 ]] && ok "трекер консистентен"; exit $rc
    ;;
  now)   # реальное время для frontmatter (created/closed) — не угадывать, а брать отсюда
    date '+%Y-%m-%d %H:%M'
    ;;
{{#if tracker=remote}}
  publish)   # текст описания для удалённого трекера: publish <ID> [--json|--diff]
    id="${1:?usage: trk.sh publish <ID> [--json|--diff]}"; shift || true
    f=$(grep -rl --include='*.md' "^id: $id\$" "$TR/tasks" "$TR/parked" "$TR/done" 2>/dev/null | head -1)
    [[ -n "$f" ]] || { fail "задача $id не найдена"; exit 1; }
    python3 "$(dirname "${BASH_SOURCE[0]}")/normalize.py" "$f" "$@"
    ;;
  next-id)   # следующий id задачи без тикета; ключи задач трекера выдаёт сам трекер
    max=$(all_ids | grep -E "^$LOCAL_PREFIX-[0-9]+$" | sed "s/^$LOCAL_PREFIX-//" | sort -n | tail -1 || true)
    printf "%s-%04d\n" "$LOCAL_PREFIX" $(( 10#${max:-0} + 1 ))
    ;;
{{#else}}
  next-id)   # следующий id задачи
    max=$(all_ids | grep -E "^$TASK_PREFIX-[0-9]+$" | sed "s/^$TASK_PREFIX-//" | sort -n | tail -1 || true)
    printf "%s-%04d\n" "$TASK_PREFIX" $(( 10#${max:-0} + 1 ))
    ;;
{{/if}}
  promote)
    id="${1:?usage: trk.sh promote <ID>}"
    f=$(grep -rl --include='*.md' "^id: $id\$" "$TR/tasks" "$TR/parked" 2>/dev/null | head -1)
    [[ -n "$f" ]] || { fail "задача $id не найдена"; exit 1; }
    is_unit_dir_main "$f" && { warn "$id уже папка"; exit 0; }
    d="${f%.md}"; n=$(basename "$f"); mkdir "$d"; git mv "$f" "$d/$n" 2>/dev/null || mv "$f" "$d/$n"
    # Строка «взято в работу» — только у задачи в работе: promote новой задачи (todo) журнал оставляет пустым.
    status=$(sed -n 's/^status: *//p' "$d/$n" | head -1 | awk '{print $1}')
    journal=""; [[ "$status" == "in-progress" ]] && journal="- $(date '+%Y-%m-%d %H:%M') — взято в работу.\n"
    printf '# %s — implementation\n\n## Как реализуем\n- \n\n## Риски\n- \n\n## Журнал\n%b' "$id" "$journal" > "$d/implementation.md"
    ok "$(rel "$d")/$n — implementation.md создан; вложения — в context/, тогда же INDEX.md (tracker/AGENTS.md)"
    ;;
  *) echo "usage: trk.sh board [--epic ID] | ready | gate | check | next-id | now | promote <ID>{{#if tracker=remote}} | publish <ID> [--json|--diff]{{/if}}"; exit 2 ;;
esac
