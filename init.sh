#!/usr/bin/env bash
# Развернуть скелет слоя агента в корень проекта по профилю (фаза 1; фаза 2 — SEED.md в Claude Code).
#
#   init.sh [DST] [--name ИМЯ] [--prefix ПРЕФИКС] [--repo ПАПКА] [--kind services|monorepo|app] [--team solo|team]
#           [--tracker local|remote] [--commit auto|ask] [--adr yes|no] [--estimates yes|no] [--toolkit yes|no] [--yes]
#   init.sh render <файл>          напечатать файл шаблона (repo-template/…) по профилю project.yaml текущего проекта
#
# Чего не хватает во флагах — спросит (терминал) или возьмёт по умолчанию (--yes или не терминал). Ответы пишутся в
# project.yaml: profile; повторный запуск в том же корне читает их оттуда, существующие файлы не трогает и докладывает
# недостающие — так добавляется профиль позже (поменял profile в project.yaml → init.sh). Что ставится при каком
# профиле — init/profiles.txt; директивы {{#if …}} в файлах скелета — init/render.py. Нужен bash ≥ 3.2 и python3.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; SRC="$HERE/skeleton"; RENDER="$HERE/init/render.py"; PROFILES="$HERE/init/profiles.txt"
command -v python3 >/dev/null || { echo "нужен python3"; exit 1; }

# yget <файл> <a.b> — скаляр из project.yaml (два уровня, как в workspace/bin/lib/common.sh)
yget() { local f="$1" key="$2"; [[ -f "$f" ]] || return 0
  if [[ "$key" == *.* ]]; then local top="${key%%.*}" sub="${key#*.}"
    awk -v t="$top" -v s="$sub" '$0 ~ "^"t":" {f=1; next} f && /^[^ #]/ {f=0} f && $0 ~ "^  "s":" {sub("^  "s":[ ]*",""); sub(/[ ]*#.*$/,""); gsub(/^"|"$/,""); print; exit}' "$f"
  else awk -v k="$key" '$0 ~ "^"k":" {sub("^"k":[ ]*",""); sub(/[ ]*#.*$/,""); gsub(/^"|"$/,""); print; exit}' "$f"; fi; }
yrepo() { awk '/^repos:/{f=1;next} f&&/^  - path:/{sub(/^  - path:[ ]*/,"");sub(/[ ]*#.*$/,"");print;exit}' "$1" 2>/dev/null || true; }

if [[ "${1:-}" == render ]]; then
  f="${2:?init.sh render <файл>}"; [[ -f "$f" ]] || f="$HERE/$f"; m="$PWD/project.yaml"; [[ -f "$m" ]] || { echo "нет project.yaml в $PWD"; exit 1; }
  set -- --set "PROJECT=$(yget "$m" name)" --set "TASK_PREFIX=$(yget "$m" task_prefix)" --set "LOCAL_PREFIX=$(yget "$m" local_prefix)" --set "REPO=$(yrepo "$m")"
  for k in kind team tracker commit adr estimates toolkit; do set -- "$@" --set "$k=$(yget "$m" profile.$k)"; done
  exec python3 "$RENDER" "$@" "$f"
fi

DST="."; YES=0
P_name=""; P_prefix=""; P_repo=""; P_kind=""; P_team=""; P_tracker=""; P_commit=""; P_adr=""; P_estimates=""; P_toolkit=""
while [[ $# -gt 0 ]]; do case "$1" in
  --name|--prefix|--repo|--kind|--team|--tracker|--commit|--adr|--estimates|--toolkit) printf -v "P_${1#--}" '%s' "$2"; shift 2;;
  --yes|-y) YES=1; shift;;
  -h|--help) sed -n 2,12p "$0"; exit 0;;
  --*) echo "неизвестный флаг $1"; exit 2;;
  *) DST="$1"; shift;;
esac; done
mkdir -p "$DST"; DST="$(cd "$DST" && pwd)"; M="$DST/project.yaml"
TTY=0; [[ -t 0 && $YES == 0 ]] && TTY=1

# ask <key> <вопрос> <по умолчанию> [допустимые|через|черту] — флаг → project.yaml → вопрос → умолчание
ask() { local k="$1" q="$2" d="$3" ok="${4:-}" var="P_$1" v
  v="${!var}"
  [[ -z "$v" ]] && case "$k" in name) v="$(yget "$M" name)";; prefix) v="$(yget "$M" task_prefix)";; repo) v="$(yrepo "$M")";; *) v="$(yget "$M" "profile.$k")";; esac
  [[ -z "$v" && $TTY == 1 ]] && { read -r -p "$q [$d]: " v || true; }
  v="${v:-$d}"
  if [[ "$k" == prefix ]]; then v="$(tr 'a-z' 'A-Z' <<<"$v")"
  elif [[ -n "$ok" ]]; then v="$(tr 'A-Z' 'a-z' <<<"$v")"; case "$v" in y|true|1|on) v=yes;; n|false|0|off) v=no;; esac; fi
  [[ -n "$ok" && "|$ok|" != *"|$v|"* ]] && { echo "$k: «$v» — допустимо: $ok"; exit 2; }
  printf -v "$var" '%s' "$v"; }

ask name      "Имя проекта" "$(basename "$DST")"
ask prefix    "Префикс id задач (ENR → ENR-0001; с удалённым трекером — его очередь)" "$(tr 'a-z' 'A-Z' <<<"${P_name:0:3}")"
ask kind      "Тип: services (несколько репо), monorepo (один репо с модулями), app (одно приложение)" services "services|monorepo|app"
[[ "$P_kind" != services ]] && ask repo "Папка репозитория кода (относительно корня проекта)" "$P_name"
ask team      "Кто работает: solo (решения и план — здесь), team (трекер и доки команды первичны, здесь копии)" solo "solo|team"
d=local; [[ "$P_team" == team ]] && d=remote
ask tracker   "Трекер: local (задачи только здесь), remote (удалённый трекер, здесь зеркало)" "$d" "local|remote"
d=auto; [[ "$P_team" == team ]] && d=ask
ask commit    "Коммит по завершении задачи: auto (сразу), ask (спросить, ждать ревью)" "$d" "auto|ask"
d=yes; [[ "$P_team" == team ]] && d=no
ask adr       "ADR и обсуждения переработок в личном слое (yes/no)" "$d" "yes|no"
ask estimates "Оценки задач, /estimate (yes/no)" no "yes|no"
ask toolkit   "Внешние наборы скиллов, toolkit-sync (yes/no)" no "yes|no"

SETS=(--set "PROJECT=$P_name" --set "TASK_PREFIX=$P_prefix" --set "LOCAL_PREFIX=LOC" --set "REPO=$P_repo")
for k in kind team tracker commit adr estimates toolkit; do var="P_$k"; SETS+=(--set "$k=${!var}"); done
echo "профиль: name=$P_name prefix=$P_prefix repo=${P_repo:-—} kind=$P_kind team=$P_team tracker=$P_tracker commit=$P_commit adr=$P_adr estimates=$P_estimates toolkit=$P_toolkit"
python3 "$RENDER" "${SETS[@]}" --profiles "$PROFILES" "$SRC" "$DST"
[[ -d "$DST/.git" ]] || { git -C "$DST" init -q; echo "git init: $DST"; }
echo "готово: $DST"
echo "дальше: склонируй репо (или положи концепт-доки в workspace/docs/), затем в Claude Code из корня — /seed (SEED.md);"
echo "        workspace/bin/agent/setup-local.sh — личный слой и хук pre-commit; workspace/bin/check/all.sh — проверки"
