# Миграция существующего проекта на единый формат

Общий порядок (для любого проекта). Ничего не удалять до шага 7; старое переносить `git mv`/копированием.

1. **Сделать корень репо**: `agent-workspace-template/init.sh <корень>` — ответить на вопросы профиля (или флаги);
   существующие файлы не перезаписывает, печатает список пропущенных: их свести с шаблоном вручную (обычно
   `CLAUDE.md`, `AGENTS.md`, `.gitignore`). Проверить, что `.gitignore` — белый список из шаблона, `git status`
   показывает **только** слой агента, а корневой `.ignore` перечисляет все репо (`!/<путь>/`) — иначе поиск агента
   их не видит.
2. **project.yaml**: репо (path, role, stack, base_branch, commit_scope, status, `commands` качества), для `services`
   — порты и `run.team`. Профиль уже записан `init.sh`.
3. **AGENTS.md корня**: перенести продукт, правила и карту из старого корневого `CLAUDE.md`/`workspace/AGENTS.md` —
   тонко (≤ ~100 строк): архитектура, модули и запуск — в `<repo>/AGENTS.md`, текущий этап — в `ROADMAP.md`/трекер.
   Устаревшие tracked-файлы в репо перечислить в `<repo>/CLAUDE.local.md`. Пути → от корня.
4. **Личное**: слой агента личный целиком — «как я запускаю» и грабли → `<repo>/CLAUDE.local.md`
   (`repo-template/CLAUDE.local.md.example`); личные скрипты/Makefile.local-прокси/хуки → `local/`;
   `workspace/bin/agent/setup-local.sh` (настройки, хук pre-commit). Секреты из `.mcp.json` → `${VAR}` + `local/.env`;
   **перевыпустить** засвеченные.
5. **Знания** → `workspace/docs/` по уровням индекса (`workspace/docs/README.md`); техдоки репо — в `<repo>/docs/`
   под карту `docs/README.md` и гейт `scripts/check-docs.sh` (`repo-template/`).
6. **Трекер** → `workspace/tracker/`: задачи получают frontmatter (`id` по `PREFIX-NNNN`; remote — id = ключ
   трекера), раскладываются по `tasks/parked/done/YYYY-MM`; большие темы — папки-эпики `tasks/<ID>-slug/<ID>-slug.md`
   с задачами внутри; задачи с контекстом — одноимённые папки. `trk.sh check` до зелёного.
7. **Репо кода**: `AGENTS.md` + `CLAUDE.md`=`@AGENTS.md` (если команда согласна; иначе не трогать, отметить в
   `CLAUDE.local.md`), `gitignore.snippet` в `.gitignore`; `check/gitignore.sh`. В tracked-файлах репо — никаких
   ссылок на слой агента.
8. **Скиллы/команды**: проектные — в `.claude/`, внешние — профиль `toolkit` (`toolkit-sync.sh`). Старые симлинки
   удалить.
9. `workspace/bin/check/all.sh` зелёный → commit → remote для корневого репо (по желанию).
