#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# cmd.sh <name> [repo…] — запустить repos[].commands.<name> (test | lint | bench | smoke | …) из корня каждого репо.
# Без repo — по всем репо, где команда задана. Список: cmd.sh list. Ничего не угадывает: нет команды — пропуск.
name="${1:-}"; shift || true
[[ -n "$name" ]] || { sed -n 3,5p "$0"; exit 2; }
if [[ "$name" == list ]]; then
  for r in ${REPOS[@]+"${REPOS[@]}"}; do for n in test lint bench smoke; do c="$(yaml_repo_cmd "$r" "$n")"; [[ -n "$c" ]] && printf "%-12s %-8s %s\n" "$r" "$n" "$c"; done; done; exit 0; fi
targets=("$@"); [[ ${#targets[@]} -eq 0 ]] && targets=(${REPOS[@]+"${REPOS[@]}"})
rc=0; ran=0
for r in "${targets[@]}"; do
  c="$(yaml_repo_cmd "$r" "$name")"; [[ -z "$c" ]] && { info "$r: команды '$name' нет в project.yaml"; continue; }
  [[ -d "$r" ]] || { warn "$r/ не склонирован"; continue; }
  info "→ $r: $c"; ran=1; (cd "$r" && bash -c "$c") && ok "$r $name" || { fail "$r $name"; rc=1; }
done
[[ $ran == 0 ]] && warn "нечего запускать"; exit $rc
