#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# Каждый repos[].path из project.yaml упомянут в таблице AGENTS.md и существует как папка.
# Каждый repos[].modules[].path упомянут в AGENTS.md строкой таблицы `<repo>/<module>/` (monorepo/app).
rc=0
for r in ${REPOS[@]+"${REPOS[@]}"}; do
  grep -qE "^\| \`$r/\`" AGENTS.md || { fail "AGENTS.md: нет строки таблицы для $r/"; rc=1; }
  [[ -d "$r" ]] || warn "$r/ не склонирован"
  while IFS= read -r m; do [[ -z "$m" ]] && continue
    grep -qE "^\| \`$r/$m/?\`" AGENTS.md || { fail "AGENTS.md: нет строки таблицы модулей для $r/$m/"; rc=1; }
    [[ -d "$r" && ! -d "$r/$m" ]] && warn "$r/$m/ нет в репо (модуль из project.yaml)"
  done < <(yaml_repo_modules "$r")
done
[[ $rc == 0 ]] && ok "манифест и AGENTS.md согласованы"; exit $rc
