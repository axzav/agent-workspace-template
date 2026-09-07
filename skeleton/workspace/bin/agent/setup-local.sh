#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# Личный слой (идемпотентно, ничего командного не трогает):
#  - .claude/settings.local.json: autoMemoryDirectory = АБСОЛЮТНЫЙ путь к workspace/memory (относительный игнорируется)
#  - local/{stack,hooks,notes,dumps}
# Переопределения инструкций сервиса — <сервис>/CLAUDE.local.md (заготовка: repo-template/CLAUDE.local.md.example).
mkdir -p local/{stack,hooks,notes,dumps} workspace/tracker/notes/private
f=.claude/settings.local.json; mem="$PROJECT_ROOT/workspace/memory"
if [[ -f "$f" ]]; then
  python3 - "$f" "$mem" <<'PY'
import json,sys; p,m=sys.argv[1:3]
try: d=json.load(open(p))
except Exception as e: print(f"✖ {p}: невалидный JSON, правь вручную ({e})"); sys.exit(1)
d["autoMemoryDirectory"]=m; json.dump(d,open(p,"w"),ensure_ascii=False,indent=2); print("✔ autoMemoryDirectory →",m)
PY
else printf '{\n  "autoMemoryDirectory": "%s",\n  "permissions": { "allow": [] }\n}\n' "$mem" > "$f"; ok "создан $f"; fi
ok "личный слой готов: $f, local/"
