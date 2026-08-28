#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# Битые относительные пути в *.md слоя агента (корень, workspace/, .claude/). Пути считаются от корня проекта
# (или от папки файла). Плейсхолдеры {{…}} и URL пропускаются.
rc=0
files=$( { find "$PROJECT_ROOT" -maxdepth 1 -name '*.md'; find "$WS_DIR" "$PROJECT_ROOT/.claude" -name '*.md' -not -path '*/context/*'; } | sort )
for f in $files; do
  paths=$( { grep -oE '(\[[^]]*\]\(([^)#]+)\)|`((workspace|\.claude|local)/[^` ]+|[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+\.md)`)' "$f" || true; } \
    | sed -E 's/^\[[^]]*\]\(([^)]+)\)$/\1/; s/^`(.*)`$/\1/' | grep -vE '^(https?:|mailto:)|\{\{' | sort -u || true )
  for p in $paths; do
    p="${p%%#*}"; [[ -z "$p" ]] && continue
    case "$p" in *'*'*|*…*|local/*|*.local.md|*settings.local.json) continue;; esac   # личное, глобы, плейсхолдеры
    top="${p%%/*}"; if [[ " ${REPOS[*]:-} " == *" $top "* && ! -d "$PROJECT_ROOT/$top" ]]; then continue; fi  # сервис не склонирован
    [[ -e "$PROJECT_ROOT/$p" || -e "$(dirname "$f")/$p" ]] || { fail "${f#$PROJECT_ROOT/}: нет $p"; rc=1; }
  done
done
[[ $rc == 0 ]] && ok "ссылки целы"; exit $rc
