# {{PROJECT}} — корень проекта

Это репозиторий **слоя агента** (карта, правила, знания, трекер), а не код. Код — в репозиториях сервисов,
которые клонируются сюда как обычные папки и в этот репо не входят.

## Развернуть с нуля
```bash
git clone <url этого репо> {{PROJECT}} && cd {{PROJECT}}
# клонировать сервисы по списку из project.yaml (repos[].path):
git clone <url backend> backend
git clone <url frontend> frontend
git clone <url infra> infra
workspace/bin/agent/setup-local.sh     # личный слой: CLAUDE.local.md, settings.local.json, память
workspace/bin/check/all.sh             # проверка: ссылки, gitignore сервисов, секреты, манифест
```

## Для агента
Точка входа — `AGENTS.md` (Claude Code читает его через `CLAUDE.md`). Запускать агент **из этой папки**.

## Структура
```
AGENTS.md / CLAUDE.md      карта и правила (команда)
CLAUDE.local.md            личные переопределения (не в git; пример — CLAUDE.local.md.example)
project.yaml               манифест: репо, префиксы, порты
.claude/                   settings.json (команда), commands/, skills/, agents/, hooks/
workspace/docs/            знания      workspace/tracker/   работа      workspace/prompts/  тела промптов
workspace/bin/             скрипты     workspace/memory/    память агента
local/                     личное (не в git): стек, хуки, заметки, дампы
<сервис>/                  репо сервисов (не в этом git)
```
