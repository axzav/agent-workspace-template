#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# git pull --ff-only во всех репо на текущих ветках; ветки не переключает.
for r in . ${REPOS[@]+"${REPOS[@]}"}; do
  [[ -d "$r/.git" ]] || { warn "$r — нет .git, пропуск"; continue; }
  info "== $r"; git -C "$r" pull --ff-only || fail "$r: ff-only не удался (разошлись?)"
done
