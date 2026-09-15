#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# Пути в *.md слоя агента (корень, workspace/, .claude/). Путь в бэктиках обязан существовать от корня проекта —
# короткая форма («targets.md», «design/README.md», «../CONCEPT.md») красная. Markdown-ссылка [текст](путь) — от корня
# или от папки файла (индекс ADR генерирует adr.sh index относительными ссылками). Плейсхолдеры {{…}} и <…>, глобы,
# «…», URL, артефакты target/ и личное (local/, *.local*) пропускаются; вложения `context/…` — от папки задачи;
# путь в репо, который не склонирован, — пропускается. Не проверяются: workspace/docs/raw/ (сырьё с цитатами),
# workspace/tracker/done/ (закрытое — история).
rc=0
files=$( { find "$PROJECT_ROOT" -maxdepth 1 -name '*.md'; find "$WS_DIR" "$PROJECT_ROOT/.claude" -name '*.md' -not -path '*/context/*' -not -path '*/docs/raw/*' -not -path '*/tracker/done/*'; } | sort )
roots="workspace|\.claude|local|agent-workspace-template"; for r in ${REPOS[@]+"${REPOS[@]}"}; do roots="$roots|$(sed 's/[.]/\\./g' <<<"$r")"; done
skip_p() { case "$1" in *'*'*|*…*|*'<'*|local/*|target/*|*/target/*|*.local.md|*settings.local.json|*'{{'*) return 0;; esac
  local top="${1%%/*}"; [[ " ${REPOS[*]:-} agent-workspace-template " == *" $top "* && ! -d "$PROJECT_ROOT/$top" ]] && return 0; return 1; }   # репо или клон шаблона не склонирован
for f in $files; do
  # 1. бэктики: `a/b.ext` или `a/b/` с известным корнем — только от корня проекта
  for p in $( { grep -oE '`(\.\.?/)?[A-Za-z0-9_.-]+(/[A-Za-z0-9_./{}…*-]+)+\.(md|sh|py|toml|yaml|yml|json|env|txt|png)`|`('"$roots"')/[^` ]*`' "$f" || true; } | tr -d '`' | sort -u ); do
    p="${p%%#*}"; skip_p "$p" && continue
    if [[ "$p" == context/* ]]; then [[ -e "$(dirname "$f")/$p" ]] || { fail "${f#$PROJECT_ROOT/}: нет вложения $p"; rc=1; }; continue; fi
    [[ -e "$PROJECT_ROOT/$p" ]] || { fail "${f#$PROJECT_ROOT/}: нет $p (путь от корня проекта)"; rc=1; }
  done
  # 2. markdown-ссылки — от корня или от папки файла
  for p in $( { grep -oE '\[[^]]*\]\([^)#]+\)' "$f" || true; } | sed -E 's/^\[[^]]*\]\(([^)]+)\)$/\1/' | grep -vE '^(https?:|mailto:)' | sort -u ); do
    skip_p "$p" && continue
    [[ -e "$PROJECT_ROOT/$p" || -e "$(dirname "$f")/$p" ]] || { fail "${f#$PROJECT_ROOT/}: нет $p"; rc=1; }
  done
done
[[ $rc == 0 ]] && ok "ссылки целы"; exit $rc
