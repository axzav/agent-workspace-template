#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# Каждый repos[].path из project.yaml упомянут в таблице AGENTS.md и существует как папка.
rc=0
for r in ${REPOS[@]+"${REPOS[@]}"}; do
  grep -qE "^\| \`$r/\`" AGENTS.md || { fail "AGENTS.md: нет строки таблицы для $r/"; rc=1; }
  [[ -d "$r" ]] || warn "$r/ не склонирован"
done
[[ $rc == 0 ]] && ok "манифест и AGENTS.md согласованы"; exit $rc
