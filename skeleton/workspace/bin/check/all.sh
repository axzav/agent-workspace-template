#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
rc=0; for s in check/links.sh check/gitignore.sh check/searchignore.sh check/secrets.sh check/manifest.sh docs/adr.sh tracker/trk.sh; do
  info "== $s"; if [[ "$s" == tracker/trk.sh || "$s" == docs/adr.sh ]]; then "$WS_BIN/$s" check || rc=1; else "$WS_BIN/$s" || rc=1; fi; done
exit $rc
