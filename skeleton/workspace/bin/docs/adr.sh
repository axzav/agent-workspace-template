#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# ADR в workspace/docs/decisions: new <slug> [название] | list | check | accept <ID> | supersede <старый> <новый> | index
# Файл NNNN-slug.md, id ADR-NNNN. Пишут только new / accept / supersede / index.
cmd="${1:-list}"; shift || true
TPL="$ADR_DIR/TEMPLATE-adr.md"; IDX="$ADR_DIR/README.md"

fm() { awk 'NR==1&&$0!="---"{exit} NR>1&&$0=="---"{exit} NR>1' "$1"; }
field() { fm "$1" | awk -v k="$2" '$0 ~ "^"k":" {sub("^"k":[ ]*",""); sub(/[ ]*#.*$/,""); gsub(/^"|"$/,""); print; exit}'; }
set_field() { # set_field <file> <key> <value> — только внутри frontmatter
  python3 - "$1" "$2" "$3" <<'PY'
import sys,re; p,k,v=sys.argv[1:4]; s=open(p).read()
head,sep,rest=s.partition('\n---\n'); assert s.startswith('---\n') and sep
lines=head.split('\n'); done=False
for i,l in enumerate(lines):
    m=re.match(r'^('+re.escape(k)+r':)[ ]*[^#]*?([ ]*#.*)?$', l)
    if m: lines[i]=f"{k}: {v}{m.group(2) or ''}"; done=True; break
if not done: lines.append(f"{k}: {v}")
open(p,'w').write('\n'.join(lines)+sep+rest)
PY
}
adrs() { ls "$ADR_DIR"/[0-9][0-9][0-9][0-9]-*.md 2>/dev/null || true; }
find_adr() { local f; for f in $(adrs); do [[ "$(field "$f" id)" == "$1" ]] && { echo "$f"; return; }; done; return 1; }
rel() { echo "${1#$PROJECT_ROOT/}"; }
today() { date '+%Y-%m-%d'; }

case "$cmd" in
  new)
    slug="${1:?usage: adr.sh new <slug> [название]}"; shift || true; title="${*:-$slug}"
    [[ -f "$TPL" ]] || { fail "нет $TPL"; exit 1; }
    max=$(adrs | sed -E 's#.*/([0-9]{4})-.*#\1#' | sort -n | tail -1); n=$(printf "%04d" $(( 10#${max:-0} + 1 )))
    out="$ADR_DIR/$n-$slug.md"; cp "$TPL" "$out"
    set_field "$out" id "ADR-$n"; set_field "$out" title "$title"; set_field "$out" date "$(today)"; set_field "$out" status proposed
    "$0" index >/dev/null; ok "$(rel "$out") — ADR-$n (proposed)"
    ;;
  list)
    printf "%-10s %-11s %-11s %s\n" "ID" "STATUS" "DATE" "TITLE"
    for f in $(adrs); do
      extra=""; s=$(field "$f" supersedes); b=$(field "$f" superseded_by)
      [[ -n "$s" ]] && extra=" (заменяет $s)"; [[ -n "$b" ]] && extra=" (заменён $b)"
      printf "%-10s %-11s %-11s %s%s\n" "$(field "$f" id)" "$(field "$f" status)" "$(field "$f" date)" "$(field "$f" title)" "$extra"
    done
    ;;
  check)
    rc=0; ids=""
    for f in $(adrs); do
      r=$(rel "$f"); id=$(field "$f" id); st=$(field "$f" status); n=$(basename "$f" | cut -c1-4)
      [[ "$id" == "ADR-$n" ]] || { fail "$r: id «$id» не совпадает с номером файла (ADR-$n)"; rc=1; }
      [[ "$st" =~ ^(proposed|accepted|rejected|superseded)$ ]] || { fail "$r: status «$st» (proposed | accepted | rejected | superseded)"; rc=1; }
      for k in title date; do [[ -z "$(field "$f" $k)" ]] && { fail "$r: нет поля $k"; rc=1; }; done
      grep -q '^## Варианты' "$f" || warn "$r: нет раздела «Варианты»"
      [[ "$st" == "accepted" ]] && grep -q '^## Открытые вопросы' "$f" && awk '/^## Открытые вопросы/{f=1;next} /^## /{f=0} f&&NF' "$f" | grep -q . && warn "$r: accepted, но раздел «Открытые вопросы» не пуст"
      b=$(field "$f" superseded_by); s=$(field "$f" supersedes)
      if [[ -n "$b" ]]; then
        [[ "$st" == "superseded" ]] || { fail "$r: superseded_by задан, но status: $st"; rc=1; }
        bf=$(find_adr "$b") || { fail "$r: superseded_by $b не существует"; rc=1; }
        [[ -n "${bf:-}" && "$(field "$bf" supersedes)" != "$id" ]] && { fail "$r: $b не ссылается обратно (supersedes: $id)"; rc=1; }
      else [[ "$st" == "superseded" ]] && { fail "$r: status superseded без superseded_by"; rc=1; }; fi
      if [[ -n "$s" ]]; then sf=$(find_adr "$s") || { fail "$r: supersedes $s не существует"; rc=1; }; fi
      ids="$ids $id"
    done
    dups=$(echo $ids | tr ' ' '\n' | sort | uniq -d); [[ -n "$dups" ]] && { fail "дубли id: $dups"; rc=1; }
    if [[ -f "$IDX" ]]; then exp=$("$0" index --print); cur=$(awk '/adr-index:start/{f=1;next} /adr-index:end/{f=0} f' "$IDX"); [[ "$exp" == "$cur" ]] || warn "$(rel "$IDX"): индекс устарел — adr.sh index"; fi
    [[ $rc == 0 ]] && ok "ADR консистентны ($(adrs | wc -l | tr -d ' '))"; exit $rc
    ;;
  accept)
    id="${1:?usage: adr.sh accept <ADR-NNNN>}"; f=$(find_adr "$id") || { fail "$id не найден"; exit 1; }
    st=$(field "$f" status); [[ "$st" == "proposed" ]] || { fail "$id: status $st, принимать можно только proposed"; exit 1; }
    set_field "$f" status accepted; set_field "$f" date "$(today)"; "$0" index >/dev/null
    ok "$id accepted ($(today)) — раздел «Открытые вопросы» удалить, решение отразить по матрице docs/README.md"
    ;;
  supersede)
    old="${1:?usage: adr.sh supersede <старый> <новый>}"; new="${2:?usage: adr.sh supersede <старый> <новый>}"
    of=$(find_adr "$old") || { fail "$old не найден"; exit 1; }; nf=$(find_adr "$new") || { fail "$new не найден"; exit 1; }
    set_field "$of" status superseded; set_field "$of" superseded_by "$new"; set_field "$nf" supersedes "$old"; "$0" index >/dev/null
    ok "$old → superseded by $new"
    ;;
  index)
    body=$(printf "| ID | Статус | Дата | Название |\n|---|---|---|---|\n"; for f in $(adrs); do printf "| [%s](%s) | %s | %s | %s |\n" "$(field "$f" id)" "$(basename "$f")" "$(field "$f" status)" "$(field "$f" date)" "$(field "$f" title)"; done)
    [[ "${1:-}" == "--print" ]] && { echo "$body"; exit 0; }
    [[ -f "$IDX" ]] || { fail "нет $IDX"; exit 1; }
    python3 - "$IDX" "$body" <<'PY'
import sys,re; p,b=sys.argv[1:3]; s=open(p).read()
new=re.sub(r'(<!-- adr-index:start[^\n]*-->\n).*?(<!-- adr-index:end -->)', lambda m: m.group(1)+b+"\n"+m.group(2), s, flags=re.S)
if new==s and 'adr-index:start' not in s: sys.exit("в README нет маркеров adr-index")
open(p,'w').write(new)
PY
    ok "индекс обновлён: $(rel "$IDX")"
    ;;
  *) echo "usage: adr.sh new <slug> [название] | list | check | accept <ID> | supersede <старый> <новый> | index"; exit 2 ;;
esac
