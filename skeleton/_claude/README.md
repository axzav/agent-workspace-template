# .claude/ — команды и настройки Claude Code

| Что | Где | Природа |
|---|---|---|
| Команды `/next-task`, `/tracker-add`, `/refine`, `/template-sync` и остальные по профилю | `.claude/commands/*.md` — шимы: читают тело из `workspace/prompts/<имя>.md` | в git |
| Разрешения по умолчанию (allow/deny) | `.claude/settings.json` | в git |
| Личные настройки: `autoMemoryDirectory`, allow-лист под абсолютные пути, личные хуки | `.claude/settings.local.json` (образец — `settings.local.json.example`; создаёт и обновляет `workspace/bin/agent/setup-local.sh`) | не в git |
| Проектные скиллы и агенты | папки `skills/` и `agents/` здесь — появляются вместе с первым файлом | в git |

## Личный слой (не в git)
| Что | Где |
|---|---|
| Инструкции агенту | `AGENTS.md` корня (весь слой личный) и `<repo>/CLAUDE.local.md` (грабли и переопределения для репо кода) |
| Личные скрипты, хуки, заметки, дампы | `local/` (`stack`, `hooks`, `notes`, `dumps`) |
| Секреты | `local/.env` → экспорт в shell; `.mcp.json` ссылается на `${VAR}` |
| Память агента | `workspace/memory/` — только факты о коде, которых нет в доках, и датированные снимки |

Каждый репо кода обязан игнорировать `CLAUDE.local.md`, `*.local*`, `.claude/settings.local.json` (его `.gitignore` или,
не трогая командные файлы, `<repo>/.git/info/exclude`) — проверяет `workspace/bin/check/gitignore.sh`; заготовка
строк — `agent-workspace-template/repo-template/gitignore.snippet`.

## Личный хук-предохранитель (пример)
PreToolUse-хук на Bash в `local/hooks/guard-stack.sh`, подключается в `settings.local.json` (см. образец): запрещает
«голый» `make`/`docker compose`, если у тебя свой стек.
```bash
#!/usr/bin/env bash
cmd=$(jq -r '.tool_input.command // empty')
if echo "$cmd" | grep -Eq '(^|[;&| ])make( |$)' && ! echo "$cmd" | grep -q 'Makefile.local'; then
  echo '{"decision":"block","reason":"Используй make -f Makefile.local <target> (см. CLAUDE.local.md репо)"}'; exit 0
fi
exit 0
```
