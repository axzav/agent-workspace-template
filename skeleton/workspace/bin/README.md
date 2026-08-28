# workspace/bin — скрипты
Все скрипты подключают `lib/common.sh` (второй строкой) и работают из корня проекта, откуда бы ни вызваны.
Список репо берётся из `project.yaml: repos[].path`.

| Скрипт | Что |
|---|---|
| `git/status.sh` | ветка / ahead-behind / грязные файлы по всем репо + корень |
| `git/pull.sh` | `git pull --ff-only` по всем репо на текущих ветках |
| `tracker/trk.sh board\|ready\|check\|gate\|next-id\|now` | дашборд трекера из frontmatter; `check` — консистентность; `gate` — exit 1, если нечего брать; `now` — время для frontmatter; `next-id` — id локальной задачи |
| `tracker/trk.sh publish <ID> [--diff\|--json]` | текст описания для удалённого трекера (тело без локальных разделов, переносы склеены, id → ключи); обёртка над `normalize.py` |
| `stack/healthcheck.sh [фильтр]` | все проверки стека из `project.yaml: run.healthcheck` + smoke-URL |
| `check/links.sh` | битые относительные пути в `*.md` слоя агента |
| `check/searchignore.sh` | корневой `.ignore` покрывает все сервисы (иначе Grep/Glob их не видят) |
| `check/gitignore.sh` | в каждом репо сервиса игнорируются `CLAUDE.local.md`, `*.local*`, `.claude/settings.local.json` |
| `check/secrets.sh` | похожие на токены строки в файлах под git |
| `check/manifest.sh` | таблица сервисов в `AGENTS.md` ⊇ `project.yaml: repos` |
| `check/all.sh` | всё выше |
| `agent/setup-local.sh` | личный слой: `CLAUDE.local.md`, `.claude/settings.local.json` (autoMemoryDirectory абсолютным путём), `local/` |
| `agent/toolkit-sync.sh` | копирует внешние скиллы из `project.yaml: toolkit.sources` в `.claude/skills/` |
