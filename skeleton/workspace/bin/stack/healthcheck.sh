#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# Прогоняет все проверки, не обрываясь на первой; фильтр — подстрока имени. Сводка в конце.
# Проверки: project.yaml run.healthcheck (общая) + repos[].commands.smoke каждого репо (запуск из корня репо).
filter="${1:-}"; declare -a names rcs; LOGDIR="$PROJECT_ROOT/local/healthcheck-logs"; mkdir -p "$LOGDIR"
run() { local name="$1"; shift; [[ -n "$filter" && "$name" != *"$filter"* ]] && return
  info "→ $name"; if "$@" >"$LOGDIR/$name.log" 2>&1; then ok "$name"; names+=("$name"); rcs+=(0); else fail "$name (лог: local/healthcheck-logs/$name.log)"; tail -5 "$LOGDIR/$name.log"; names+=("$name"); rcs+=(1); fi; }
hc="$(yaml_get run.healthcheck)"; [[ -n "$hc" ]] && run "team-healthcheck" bash -c "$hc"
for r in ${REPOS[@]+"${REPOS[@]}"}; do c="$(yaml_repo_cmd "$r" smoke)"; [[ -n "$c" && -d "$r" ]] && run "smoke-$r" bash -c "cd '$r' && $c"; done
[[ ${#names[@]} -eq 0 ]] && { warn "проверок нет: заполни run.healthcheck или repos[].commands.smoke в project.yaml"; exit 0; }
echo; for i in "${!names[@]}"; do printf "%-24s %s\n" "${names[$i]}" "$([[ ${rcs[$i]} == 0 ]] && echo OK || echo FAIL)"; done
for c in "${rcs[@]:-0}"; do [[ $c != 0 ]] && exit 1; done; exit 0
