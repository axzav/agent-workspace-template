# Личный слой (не в git)

| Что | Где | Зачем |
|---|---|---|
| Личные инструкции агенту | `CLAUDE.local.md` (корень), при необходимости `<сервис>/CLAUDE.local.md` | переопределяют командный способ запуска, креды, запреты |
| Личные настройки Claude Code | `.claude/settings.local.json` | allow-лист, `autoMemoryDirectory`, личные хуки |
| Личный стек, скрипты, заметки, дампы | `local/` (`local/stack`, `local/hooks`, `local/notes`, `local/dumps`) | всё, что не должно проходить ревью |
| Секреты | `local/.env` → экспорт в shell; `.mcp.json` ссылается на `${VAR}` | в файлах репо секретов нет |

Требование к репо сервисов: `CLAUDE.local.md`, `*.local*`, `.claude/settings.local.json` — в их `.gitignore`
(проверка: `workspace/bin/check/gitignore.sh`).

## Пример личного предохранителя `local/hooks/guard-stack.sh`
PreToolUse-хук на Bash, запрещающий «голый» `make`/`docker compose`, если у тебя свой стек:
```bash
#!/usr/bin/env bash
# deny, если команда содержит make без "-f Makefile.local" или docker compose без "-p my-project"
cmd=$(jq -r '.tool_input.command // empty')
if echo "$cmd" | grep -Eq '(^|[;&| ])make( |$)' && ! echo "$cmd" | grep -q 'Makefile.local'; then
  echo '{"decision":"block","reason":"Используй make -f Makefile.local <target> (см. CLAUDE.local.md)"}'; exit 0
fi
exit 0
```
