#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# В каждом репо сервиса личные файлы агента должны игнорироваться.
rc=0
for r in ${REPOS[@]+"${REPOS[@]}"}; do
  [[ -d "$r/.git" ]] || { warn "$r: нет .git"; continue; }
  for p in CLAUDE.local.md .claude/settings.local.json Makefile.local; do
    git -C "$r" check-ignore -q "$p" || { fail "$r: $p НЕ игнорируется"; rc=1; }
  done
  for p in CLAUDE.md AGENTS.md; do
    [[ -f "$r/$p" ]] && ! git -C "$r" ls-files --error-unmatch "$p" >/dev/null 2>&1 && ! git -C "$r" check-ignore -q "$p" \
      && { warn "$r: $p untracked и не ignored — либо закоммитить, либо в .gitignore"; }
  done
done
[[ $rc == 0 ]] && ok "gitignore сервисов в порядке"; exit $rc
