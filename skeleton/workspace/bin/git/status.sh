#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# Сводка по всем репо: ветка, ahead/behind, грязные файлы. Ничего не меняет.
for r in . ${REPOS[@]+"${REPOS[@]}"}; do
  name=$([[ "$r" == "." ]] && echo "(корень)" || echo "$r")
  if [[ ! -d "$r/.git" ]]; then warn "$name — нет .git"; continue; fi
  br=$(git -C "$r" symbolic-ref --short -q HEAD || echo "(detached)")
  if lr=$(git -C "$r" rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null); then ab=$(echo "$lr" | awk '{print "↓"$1" ↑"$2}'); else ab="нет upstream"; fi
  dirty=$(git -C "$r" status --porcelain | wc -l | tr -d ' ')
  printf "%-14s %-28s %-14s %s\n" "$name" "$br" "$ab" "$([[ $dirty == 0 ]] && echo "чисто" || echo "${C_YEL}изменений: $dirty${C_OFF}")"
done
