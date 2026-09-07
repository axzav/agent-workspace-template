#!/usr/bin/env bash
# Общий пролог скриптов воркспейса: cd в корень проекта, список репо из project.yaml, цвета.
set -euo pipefail
WS_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "$WS_BIN/../.." && pwd)"
WS_DIR="$PROJECT_ROOT/workspace"
MANIFEST="$PROJECT_ROOT/project.yaml"
cd "$PROJECT_ROOT"

# yaml_get <key> — скалярное значение верхнего уровня или "a.b" (два уровня, без списков)
yaml_get() {
  local key="$1"
  if [[ "$key" == *.* ]]; then
    local top="${key%%.*}" sub="${key#*.}"
    awk -v t="$top" -v s="$sub" '
      $0 ~ "^"t":" {f=1; next}
      f && /^[^ #]/ {f=0}
      f && $0 ~ "^  "s":" {sub("^  "s":[ ]*",""); sub(/[ ]*#.*$/,""); gsub(/^"|"$/,""); print; exit}' "$MANIFEST"
  else
    awk -v k="$key" '$0 ~ "^"k":" {sub("^"k":[ ]*",""); sub(/[ ]*#.*$/,""); gsub(/^"|"$/,""); print; exit}' "$MANIFEST"
  fi
}
# yaml_list <top>.<field> — значения поля field у элементов списка top (repos.path, toolkit.sources как inline-список)
yaml_list() {
  local top="${1%%.*}" field="${1#*.}"
  awk -v t="$top" -v f="$field" '
    $0 ~ "^"t":" {
      line=$0; sub("^"t":[ ]*","",line); sub(/[ ]*#.*$/,"",line)
      if (line ~ /^\[/) { gsub(/[\[\]"]/,"",line); n=split(line,a,/,[ ]*/); for(i=1;i<=n;i++) if(a[i]!="") print a[i]; exit }
      inl=1; next }
    inl && /^[^ #]/ {inl=0}
    inl && $0 ~ "^  - "f":" {sub("^  - "f":[ ]*",""); sub(/[ ]*#.*$/,""); gsub(/^"|"$/,""); print}
    inl && $0 ~ "^    "f":" {sub("^    "f":[ ]*",""); sub(/[ ]*#.*$/,""); gsub(/^"|"$/,""); print}' "$MANIFEST"
}
# yaml_repo_get <path> <field> — скалярное поле элемента repos[] с данным path (role, stack, status, …)
yaml_repo_get() {
  awk -v p="$1" -v f="$2" '
    /^repos:/ {inl=1; next}
    inl && /^[^ #]/ {inl=0}
    inl && $0 ~ "^  - path:[ ]*"p"([ ]*#.*)?$" {cur=1; next}
    inl && /^  - / {cur=0}
    inl && cur && $0 ~ "^    "f":" {sub("^    "f":[ ]*",""); sub(/[ ]*#.*$/,""); gsub(/^"|"$/,""); print; exit}' "$MANIFEST"
}
# yaml_repo_cmd <path> <name> — команда качества repos[].commands.<name> (пусто — не задана)
yaml_repo_cmd() {
  awk -v p="$1" -v n="$2" '
    /^repos:/ {inl=1; next}
    inl && /^[^ #]/ {inl=0}
    inl && $0 ~ "^  - path:[ ]*"p"([ ]*#.*)?$" {cur=1; next}
    inl && /^  - / {cur=0; inc=0}
    inl && cur && /^    commands:/ {inc=1; next}
    inl && cur && inc && /^    [^ ]/ {inc=0}
    inl && cur && inc && $0 ~ "^      "n":" {sub("^      "n":[ ]*",""); sub(/[ ]*#.*$/,""); gsub(/^"|"$/,""); print; exit}' "$MANIFEST"
}
# yaml_repo_modules <path> — path каждого модуля repos[].modules[] (пусто — модулей нет или modules: [])
yaml_repo_modules() {
  awk -v p="$1" '
    /^repos:/ {inl=1; next}
    inl && /^[^ #]/ {inl=0}
    inl && $0 ~ "^  - path:[ ]*"p"([ ]*#.*)?$" {cur=1; next}
    inl && /^  - / {cur=0; inm=0}
    inl && cur && /^    modules:/ {line=$0; sub(/^    modules:[ ]*/,"",line); sub(/[ ]*#.*$/,"",line); if (line ~ /^\[/) {exit}; inm=1; next}
    inl && cur && inm && /^    [^ ]/ {inm=0}
    inl && cur && inm && /^      - path:/ {sub(/^      - path:[ ]*/,""); sub(/[ ]*#.*$/,""); gsub(/^"|"$/,""); print}' "$MANIFEST"
}
PROJECT_NAME="$(yaml_get name)"
PROJECT_KIND="$(yaml_get kind)"; PROJECT_KIND="${PROJECT_KIND:-services}"
TASK_PREFIX="$(yaml_get task_prefix)"
LOCAL_PREFIX="$(yaml_get local_prefix)"; LOCAL_PREFIX="${LOCAL_PREFIX:-LOC}"
TRACKER_MODE="$(yaml_get tracker.mode)"; TRACKER_MODE="${TRACKER_MODE:-local}"
REPOS=()
while IFS= read -r r; do [[ -n "$r" ]] && REPOS+=("$r"); done < <(yaml_list repos.path)

if [[ -t 1 ]]; then C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'; C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
else C_RED=""; C_GRN=""; C_YEL=""; C_DIM=""; C_OFF=""; fi
info() { echo "${C_DIM}$*${C_OFF}"; }
ok()   { echo "${C_GRN}✔${C_OFF} $*"; }
warn() { echo "${C_YEL}▲${C_OFF} $*"; }
fail() { echo "${C_RED}✖${C_OFF} $*"; }
