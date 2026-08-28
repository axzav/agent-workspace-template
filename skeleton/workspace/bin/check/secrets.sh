#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# Похожие на секреты строки в файлах под git корневого репо.
pat='(Bearer [A-Za-z0-9_\-]{16,}|mcp_[a-f0-9]{16,}|y0__[A-Za-z0-9_\-]{20,}|hf_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|xox[abp]-[0-9A-Za-z\-]{10,}|ghp_[A-Za-z0-9]{30,}|glpat-[A-Za-z0-9_\-]{20})'
hits=$(git ls-files -z | xargs -0 grep -nE "$pat" 2>/dev/null | grep -v 'check/secrets.sh' || true)
[[ -z "$hits" ]] && { ok "секретов не найдено"; exit 0; }
fail "похоже на секреты:"; echo "$hits"; exit 1
