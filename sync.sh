#!/usr/bin/env bash
# Сверка и обновление слоя агента развёрнутого проекта с шаблоном — в обе стороны (init.sh существующие файлы не трогает).
#
#   sync.sh [DST] status [--files GLOB…]   что расходится: скелет по профилю проекта против файлов проекта
#   sync.sh [DST] diff   [--files GLOB…]   unified diff расхождений (шаблон → проект)
#   sync.sh [DST] pull   [--files GLOB…]   изменения шаблона с момента маркера — в проект (трёхстороннее слияние)
#   sync.sh [DST] push   [--files GLOB…]   изменения проекта с момента маркера — в skeleton/ (трёхстороннее слияние)
#   sync.sh [DST] mark                     записать маркер в project.yaml: template.commit (HEAD шаблона),
#                                          template.project_commit (HEAD корня проекта), template.synced
#
# DST — корень проекта (по умолчанию текущий каталог); нужен project.yaml с профилем (profile: …, его пишет init.sh).
# Маркер — точка последней сходимости, база трёхстороннего слияния (git merge-file): pull сливает в файл проекта
# дельту скелета между template.commit и HEAD (рендер по профилю обеих сторон), push сливает в skeleton/ дельту файла
# проекта между template.project_commit и рабочей копией. Так специализация проекта (имя репо вместо {{REPO}},
# термины продукта) при pull сохраняется, а при push не уезжает в шаблон — уезжают только правки с момента маркера;
# строки с плейсхолдерами дают конфликт — его и обобщение формулировок разбирает человек или /template-sync.
# Без маркера — только status/diff: сверить руками, затем mark. Проектные файлы (засеянные SEED: AGENTS.md,
# манифест, карты доков, ROADMAP, память) не сверяются — список SEEDED ниже и project.yaml: template.skip.
# При конфликте в файле остаются маркеры <<<<<<<, код возврата 1, маркер не двигается. Нужен bash ≥ 3.2, python3, git.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; SRC="$HERE/skeleton"; RENDER="$HERE/init/render.py"; PROFILES="$HERE/init/profiles.txt"
command -v python3 >/dev/null || { echo "нужен python3"; exit 1; }

SEEDED="AGENTS.md CLAUDE.md project.yaml .gitignore .ignore .mcp.json workspace/docs/README.md workspace/docs/ROADMAP.md
workspace/memory/MEMORY.md workspace/docs/knowledgebase/README.md workspace/docs/contracts/README.md workspace/docs/dev/README.md"
# каталоги, где файл проекта без пары в скелете — находка для push (ONLY-IN-PROJECT)
TOOL_DIRS=".claude/commands workspace/bin workspace/prompts"

yget() { local f="$1" key="$2"; [[ -f "$f" ]] || return 0
  if [[ "$key" == *.* ]]; then local top="${key%%.*}" sub="${key#*.}"
    awk -v t="$top" -v s="$sub" '$0 ~ "^"t":" {f=1; next} f && /^[^ #]/ {f=0} f && $0 ~ "^  "s":" {sub("^  "s":[ ]*",""); sub(/[ ]*#.*$/,""); gsub(/^"|"$/,""); print; exit}' "$f"
  else awk -v k="$key" '$0 ~ "^"k":" {sub("^"k":[ ]*",""); sub(/[ ]*#.*$/,""); gsub(/^"|"$/,""); print; exit}' "$f"; fi; }
yrepo() { awk '/^repos:/{f=1;next} f&&/^  - path:/{sub(/^  - path:[ ]*/,"");sub(/[ ]*#.*$/,"");print;exit}' "$1" 2>/dev/null || true; }
ylist() { local v; v="$(yget "$1" "$2")"; v="${v#[}"; v="${v%]}"; tr ',' ' ' <<<"$v" | tr -d '"'; }

DST="."; CMD=""; GLOBS=()
while [[ $# -gt 0 ]]; do case "$1" in
  status|diff|pull|push|mark) CMD="$1"; shift;;
  --files) shift; while [[ $# -gt 0 && "$1" != --* ]]; do GLOBS+=("$1"); shift; done;;
  -h|--help) sed -n 2,18p "$0"; exit 0;;
  --*) echo "неизвестный флаг $1"; exit 2;;
  *) DST="$1"; shift;;
esac; done
[[ -n "$CMD" ]] || { sed -n 2,8p "$0"; exit 2; }
DST="$(cd "$DST" && pwd)"; M="$DST/project.yaml"
[[ -f "$M" ]] || { echo "нет $M — сначала init.sh"; exit 1; }
[[ -n "$(yget "$M" profile.kind)" ]] || { echo "в $M нет profile: — допиши (ключи — skeleton/project.yaml) или запусти init.sh"; exit 1; }

SETS=(--set "PROJECT=$(yget "$M" name)" --set "TASK_PREFIX=$(yget "$M" task_prefix)" --set "LOCAL_PREFIX=$(yget "$M" local_prefix)" --set "REPO=$(yrepo "$M")")
for k in kind team tracker commit adr; do SETS+=(--set "$k=$(yget "$M" profile.$k)"); done
SKIP="$(tr '\n' ' ' <<<"$SEEDED") $(ylist "$M" template.skip)"
MARK="$(yget "$M" template.commit)"; PMARK="$(yget "$M" template.project_commit)"
HEAD_SHA="$(git -C "$HERE" rev-parse --short HEAD)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

render_tree() { python3 "$RENDER" "${SETS[@]}" --profiles "$PROFILES" "$1" "$2" >/dev/null; }   # SRC_DIR → DST_DIR
render_head() { mkdir -p "$TMP/head"; render_tree "$SRC" "$TMP/head"; }
render_base() {   # скелет на коммите маркера → $TMP/base
  [[ -n "$MARK" ]] || { echo "нет маркера template.commit в project.yaml: сверь по status/diff, затем sync.sh mark"; exit 1; }
  git -C "$HERE" cat-file -e "$MARK^{commit}" 2>/dev/null || { echo "коммита $MARK нет в клоне шаблона (git -C $HERE fetch?)"; exit 1; }
  mkdir -p "$TMP/base_src" "$TMP/base"; git -C "$HERE" archive "$MARK" skeleton | tar -x -C "$TMP/base_src"
  render_tree "$TMP/base_src/skeleton" "$TMP/base"; }
rel_files() { (cd "$1" && find . -type f | sed 's|^\./||' | sort); }
skipped() { [[ " $SKIP " == *" $1 "* ]]; }
selected() { [[ ${#GLOBS[@]} -eq 0 ]] && return 0; local g; for g in "${GLOBS[@]}"; do case "$1" in $g) return 0;; esac; done; return 1; }
skel_path() { case "$1" in .claude/*) echo "$SRC/_claude/${1#.claude/}";; .gitignore) echo "$SRC/_gitignore";; *) echo "$SRC/$1";; esac; }   # rel проекта → файл skeleton/
fix_mode() { case "$1" in *.sh|*.py|*/hooks/*|*/pre-commit) chmod 755 "$2";; esac; }
same() { cmp -s "$1" "$2"; }
only_in_project() { local d; for d in $TOOL_DIRS; do [[ -d "$DST/$d" ]] || continue
  (cd "$DST" && find "$d" -type f -not -name '*.local*' | sort) | while read -r p; do [[ -f "$TMP/head/$p" ]] || echo "$p"; done; done
  for p in "$DST"/workspace/tracker/TEMPLATE-*.md; do [[ -f "$p" ]] || continue; p="${p#$DST/}"; [[ -f "$TMP/head/$p" ]] || echo "$p"; done; }
header() { echo "шаблон: $HEAD_SHA ($HERE)  проект: $DST  маркер: шаблон ${MARK:-нет}, проект ${PMARK:-нет}"
  [[ -n "$MARK" ]] && git -C "$HERE" cat-file -e "$MARK^{commit}" 2>/dev/null && { n=$(git -C "$HERE" rev-list --count "$MARK..HEAD" -- skeleton init); echo "коммитов шаблона по skeleton/ после маркера: $n"; }
  [[ -n "$PMARK" ]] && git -C "$DST" cat-file -e "$PMARK^{commit}" 2>/dev/null && { n=$(git -C "$DST" rev-list --count "$PMARK..HEAD" -- $TOOL_DIRS workspace/tracker); echo "коммитов проекта по инструментальным файлам после маркера: $n"; }
  [[ -z "$(git -C "$HERE" status --porcelain -- skeleton init)" ]] || echo "внимание: skeleton/ в клоне шаблона не закоммичен"; }

case "$CMD" in
status)
  header; render_head
  n_same=0; n_diff=0; n_miss=0; n_skip=0
  for f in $(rel_files "$TMP/head"); do selected "$f" || continue
    if skipped "$f"; then n_skip=$((n_skip+1)); continue; fi
    if [[ ! -f "$DST/$f" ]]; then echo "MISSING   $f"; n_miss=$((n_miss+1))
    elif same "$TMP/head/$f" "$DST/$f"; then n_same=$((n_same+1))
    else echo "DIFF      $f"; n_diff=$((n_diff+1)); fi; done
  for f in $(only_in_project); do selected "$f" || continue; echo "ONLY-IN-PROJECT  $f"; done
  echo "совпадают: $n_same  расходятся: $n_diff  нет в проекте: $n_miss  проектные (не сверяются): $n_skip"
  ;;
diff)
  render_head
  for f in $(rel_files "$TMP/head"); do selected "$f" || continue; skipped "$f" && continue
    [[ -f "$DST/$f" ]] || { echo "### $f — нет в проекте"; continue; }
    same "$TMP/head/$f" "$DST/$f" && continue
    echo "### $f (шаблон → проект)"; diff -u --label "шаблон/$f" --label "проект/$f" "$TMP/head/$f" "$DST/$f" || true; done
  ;;
pull)
  header; render_base; render_head
  rc=0; upd=(); new=(); conf=(); kept=()
  for f in $(rel_files "$TMP/head"); do selected "$f" || continue; skipped "$f" && continue
    h="$TMP/head/$f"; b="$TMP/base/$f"; o="$DST/$f"
    if [[ ! -f "$o" ]]; then
      if [[ -f "$b" && ${#GLOBS[@]} -eq 0 ]]; then kept+=("$f (удалён в проекте)"); continue; fi
      mkdir -p "$(dirname "$o")"; cp "$h" "$o"; fix_mode "$f" "$o"; new+=("$f"); continue; fi
    same "$h" "$o" && continue
    if [[ ! -f "$b" ]]; then b="$TMP/empty"; : > "$b"; fi
    same "$b" "$h" && continue                      # шаблон не менялся — расхождение = специализация проекта
    if same "$b" "$o"; then cp "$h" "$o"; fix_mode "$f" "$o"; upd+=("$f"); continue; fi
    cp "$o" "$TMP/was"
    if git merge-file -L "проект" -L "база $MARK" -L "шаблон $HEAD_SHA" "$o" "$b" "$h"; then same "$TMP/was" "$o" || upd+=("$f (слито)")
    else conf+=("$f"); rc=1; fi; done
  [[ ${#new[@]} -gt 0 ]]  && { echo "создано:";   printf '  %s\n' "${new[@]}"; }
  [[ ${#upd[@]} -gt 0 ]]  && { echo "обновлено:"; printf '  %s\n' "${upd[@]}"; }
  [[ ${#kept[@]} -gt 0 ]] && { echo "пропущено:"; printf '  %s\n' "${kept[@]}"; }
  if [[ ${#conf[@]} -gt 0 ]]; then echo "конфликты (маркеры <<<<<<< в файлах; разреши и запусти sync.sh mark):"; printf '  %s\n' "${conf[@]}"
  elif [[ ${#GLOBS[@]} -eq 0 ]]; then "$0" "$DST" mark; else echo "частичный pull (--files): маркер не сдвинут"; fi
  exit $rc
  ;;
push)
  header; render_head
  [[ -n "$PMARK" ]] || { echo "нет маркера template.project_commit: закоммить корень проекта и запусти sync.sh mark"; exit 1; }
  git -C "$DST" cat-file -e "$PMARK^{commit}" 2>/dev/null || { echo "коммита $PMARK нет в корне проекта"; exit 1; }
  rc=0; upd=(); conf=(); mkdir -p "$TMP/pbase"
  for f in $(rel_files "$TMP/head"); do selected "$f" || continue; skipped "$f" && continue
    o="$DST/$f"; h="$TMP/head/$f"; s="$(skel_path "$f")"; b="$TMP/pbase/$f"
    [[ -f "$o" && -f "$s" ]] || continue
    same "$h" "$o" && continue                      # проект = шаблон
    mkdir -p "$(dirname "$b")"; git -C "$DST" show "$PMARK:$f" > "$b" 2>/dev/null || continue   # файла не было на маркере
    same "$b" "$o" && continue                      # проект не менял файл с маркера
    cp "$s" "$TMP/was"
    if git merge-file -L "шаблон $HEAD_SHA" -L "проект на $PMARK" -L "проект" "$s" "$b" "$o"; then same "$TMP/was" "$s" || upd+=("$f")
    else conf+=("$f"); rc=1; fi; done
  [[ ${#upd[@]} -gt 0 ]] && { echo "перенесено в skeleton/ (проверь: имя репо → {{REPO}}, термины продукта → общие):"; printf '  %s\n' "${upd[@]}"; }
  [[ ${#conf[@]} -gt 0 ]] && { echo "конфликты в skeleton/ (маркеры <<<<<<<; обычно строки с плейсхолдерами):"; printf '  %s\n' "${conf[@]}"; }
  [[ ${#upd[@]} -eq 0 && ${#conf[@]} -eq 0 ]] && echo "в проекте нет изменений инструментальных файлов с маркера $PMARK"
  echo "дальше: git -C $HERE diff — проверить, закоммитить шаблон, затем sync.sh mark"
  exit $rc
  ;;
mark)
  [[ -z "$(git -C "$HERE" status --porcelain -- skeleton init)" ]] || echo "внимание: skeleton/ не закоммичен — маркер укажет на HEAD без этих правок"
  PC="$(git -C "$DST" rev-parse --short HEAD 2>/dev/null || true)"
  [[ -n "$PC" ]] || echo "внимание: в корне проекта нет коммитов — project_commit пуст, push недоступен до первого коммита и mark"
  python3 - "$M" "$HEAD_SHA" "$PC" "$(date +%Y-%m-%d)" <<'EOF'
import re, sys
p, sha, pc, day = sys.argv[1:5]
s = open(p, encoding='utf-8').read()
block = (f"template:                           # agent-workspace-template: точка последней сходимости (sync.sh mark) — база для pull/push\n"
         f"  commit: {sha}                     # коммит шаблона\n  project_commit: {pc}             # коммит корня проекта\n  synced: {day}\n")
m = re.search(r'^template:.*\n(?:  .*\n?)*', s, re.M)          # блок template: до первой строки без отступа
if m:
    blk = re.sub(r'^(  commit:)[ ]*\S*', rf'\1 {sha}', m.group(0), count=1, flags=re.M)
    blk = re.sub(r'^(  synced:)[ ]*\S*', rf'\1 {day}', blk, count=1, flags=re.M)
    if re.search(r'^  project_commit:', blk, re.M):
        blk = re.sub(r'^(  project_commit:)[ ]*\S*', rf'\1 {pc}', blk, count=1, flags=re.M)
    else:
        blk = re.sub(r'^(  commit:.*\n)', rf'\1  project_commit: {pc}\n', blk, count=1, flags=re.M)
    s = s[:m.start()] + blk + s[m.end():]
else:
    s = s.rstrip('\n') + '\n\n' + block
open(p, 'w', encoding='utf-8').write(s)
EOF
  echo "маркер: template.commit = $HEAD_SHA, project_commit = ${PC:-—} ($M)"
  ;;
esac
