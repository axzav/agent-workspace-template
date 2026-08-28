# Миграция существующего проекта на единый формат

Общий порядок (для любого проекта). Ничего не удалять до шага 7; старое переносить `git mv`/копированием.

1. **Сделать корень репо**: `template/init.sh <name> <PREFIX> <корень>` — существующие файлы не перезаписывает,
   печатает список пропущенных: их свести с шаблоном вручную (обычно `CLAUDE.md`, `AGENTS.md`, `.gitignore`).
   Проверить, что `.gitignore` — белый список из шаблона, `git status` показывает **только** слой агента,
   а корневой `.ignore` перечисляет все сервисы (`!/<путь>/`) — иначе поиск агента их не видит.
2. **project.yaml**: перечислить репо (path, role, stack, base_branch, commit_scope, status), порты, `run.team`,
   `tracker.mode`, `toolkit.sources`.
3. **AGENTS.md корня**: перенести карту, связи, правила из старого корневого `CLAUDE.md`/`workspace/AGENTS.md`.
   Устаревшие tracked-файлы в сервисах перечислить явно. Пути → от корня.
4. **Личное**: всё «как я запускаю» → `CLAUDE.local.md`; личные скрипты/Makefile.local-прокси/хуки → `local/`;
   `workspace/bin/agent/setup-local.sh`. Секреты из `.mcp.json` → `${VAR}` + `local/.env`; **перевыпустить** засвеченные.
5. **Знания** → `workspace/docs/` по индексу (knowledgebase / contracts / dev / raw / features).
6. **Трекер** → `workspace/tracker/`: задачи получают frontmatter (`id` по `PREFIX-NNNN`, старый ключ удалённого
   трекера — в `remote:`), раскладываются по `tasks/parked/done/YYYY-MM`; большие темы — папки-эпики `tasks/<ID>-slug/<ID>-slug.md` с контекстом и задачами внутри; задачи с контекстом — одноимённые папки.
   `trk.sh check` до зелёного.
7. **Сервисы**: `AGENTS.md` + `CLAUDE.md`=`@AGENTS.md` (если команда согласна; иначе не трогать, отметить в карте),
   `gitignore.snippet` в `.gitignore`; `check/gitignore.sh`.
8. **Скиллы/команды**: проектные — в `.claude/`, внешние — `toolkit-sync.sh`. Старые симлинки удалить.
9. `workspace/bin/check/all.sh` зелёный → commit → remote для корневого репо.
