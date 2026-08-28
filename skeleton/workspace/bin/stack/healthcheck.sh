#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# Прогоняет все проверки, не обрываясь на первой; фильтр — подстрока имени. Сводка в конце.
filter="${1:-}"; declare -a names rcs; LOGDIR="$PROJECT_ROOT/local/healthcheck-logs"; mkdir -p "$LOGDIR"
run() { local name="$1"; shift; [[ -n "$filter" && "$name" != *"$filter"* ]] && return
  info "→ $name"; if "$@" >"$LOGDIR/$name.log" 2>&1; then ok "$name"; names+=("$name"); rcs+=(0); else fail "$name (лог: local/healthcheck-logs/$name.log)"; tail -5 "$LOGDIR/$name.log"; names+=("$name"); rcs+=(1); fi; }
hc="$(yaml_get run.healthcheck)"; [[ -n "$hc" ]] && run "team-healthcheck" bash -c "$hc"
for r in ${REPOS[@]+"${REPOS[@]}"}; do [[ -f "$r/Makefile" ]] && grep -q '^smoke:' "$r/Makefile" && run "smoke-$r" make -C "$r" smoke; done
echo; for i in "${!names[@]}"; do printf "%-24s %s\n" "${names[$i]}" "$([[ ${rcs[$i]} == 0 ]] && echo OK || echo FAIL)"; done
for c in "${rcs[@]:-0}"; do [[ $c != 0 ]] && exit 1; done; exit 0
