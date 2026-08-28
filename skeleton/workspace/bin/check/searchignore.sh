#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# Корневой .ignore возвращает сервисы в поиск (Grep/Glob уважают .gitignore). Каждый repos[].path — строкой !/<путь>/.
rc=0
[[ -f .ignore ]] || { fail ".ignore отсутствует — Grep/Glob из корня не видят папки сервисов"; exit 1; }
for r in ${REPOS[@]+"${REPOS[@]}"}; do
  grep -qxF "!/$r/" .ignore || { fail ".ignore: нет строки !/$r/ — $r/ невидим для поиска из корня"; rc=1; }
done
[[ $rc == 0 ]] && ok ".ignore покрывает все сервисы"; exit $rc
