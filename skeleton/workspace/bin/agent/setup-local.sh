#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# Личный слой (идемпотентно, ничего командного не трогает):
#  - .claude/settings.local.json: autoMemoryDirectory = АБСОЛЮТНЫЙ путь к workspace/memory (относительный игнорируется);
#    allow-правило на скрипты по абсолютному пути (правила велят звать их так — Bash(workspace/bin/*) из settings.json
#    абсолютную форму не покрывает)
#  - local/{stack,hooks,notes,dumps}, workspace/tracker/notes/private
#  - core.hooksPath корневого репо → workspace/bin/git/hooks (pre-commit = check/all.sh)
# Переопределения инструкций репо кода — <repo>/CLAUDE.local.md (заготовка: agent-workspace-template/repo-template/CLAUDE.local.md.example).
mkdir -p local/{stack,hooks,notes,dumps} workspace/tracker/notes/private
f=.claude/settings.local.json; mem="$PROJECT_ROOT/workspace/memory"; allow="Bash($PROJECT_ROOT/workspace/bin/*)"
[[ -f "$f" ]] || printf '{\n  "permissions": { "allow": [] }\n}\n' > "$f"
python3 - "$f" "$mem" "$allow" <<'PY'
import json,sys; p,m,a=sys.argv[1:4]
try: d=json.load(open(p))
except Exception as e: print(f"✖ {p}: невалидный JSON, правь вручную ({e})"); sys.exit(1)
d["autoMemoryDirectory"]=m
al=d.setdefault("permissions",{}).setdefault("allow",[])
if a not in al: al.append(a)
json.dump(d,open(p,"w"),ensure_ascii=False,indent=2); open(p,"a").write("\n"); print("✔ autoMemoryDirectory →",m); print("✔ allow:",a)
PY
git config core.hooksPath workspace/bin/git/hooks && ok "core.hooksPath → workspace/bin/git/hooks (pre-commit: check/all.sh)"
ok "личный слой готов: $f, local/"
