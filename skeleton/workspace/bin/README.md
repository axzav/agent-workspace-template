# workspace/bin — скрипты
Все скрипты подключают `workspace/bin/lib/common.sh` (второй строкой) и работают из корня проекта, откуда бы ни
вызваны; звать — абсолютным путём. Список репо, команды качества и профиль — из `project.yaml`.

| Скрипт | Что |
|---|---|
| `workspace/bin/tracker/trk.sh board \| ready \| gate \| check \| next-id \| now \| promote <ID>` | трекер из frontmatter: дашборд, что можно брать (`gate` — код 1, если нечего; когда пусто — почему держится очередь), консистентность, следующий id, время для frontmatter, файл задачи → папка с `implementation.md` |
{{#if tracker=remote}}
| `workspace/bin/tracker/trk.sh publish <ID> [--diff \| --json]` | текст описания для удалённого трекера (тело без frontmatter, переносы склеены, ссылки на локальные файлы сняты); обёртка над `normalize.py` |
{{/if}}
| `workspace/bin/stack/cmd.sh <name> [repo…]` | команда качества `project.yaml: repos[].commands.<name>` из корня репо; `list` — что задано |
{{#if kind=services}}
| `workspace/bin/stack/healthcheck.sh [фильтр]` | `run.healthcheck` + `repos[].commands.smoke` по всем репо, не обрываясь; логи в `local/healthcheck-logs/` |
{{/if}}
{{#if adr}}
| `workspace/bin/docs/adr.sh new \| list \| check \| accept \| supersede \| index` | ADR в `workspace/docs/decisions/`: номер и файл из шаблона, индекс в README, проверка статусов и ссылок замены |
{{/if}}
| `workspace/bin/check/all.sh` | все проверки слоя ниже; их же гоняет хук pre-commit корневого репо |
| `workspace/bin/check/links.sh` | пути в `*.md` слоя: в бэктиках — от корня проекта, markdown-ссылки — от корня или от папки файла; `done/` и `raw/` не проверяются |
| `workspace/bin/check/gitignore.sh` | каждый репо игнорирует `CLAUDE.local.md`, `*.local*`, `.claude/settings.local.json` |
| `workspace/bin/check/searchignore.sh` | корневой `.ignore` покрывает все репо (иначе Grep/Glob их не видят) |
| `workspace/bin/check/secrets.sh` | похожие на токены строки в файлах под git |
| `workspace/bin/check/manifest.sh` | карта проекта в `AGENTS.md` ⊇ `project.yaml: repos` |
| `workspace/bin/git/status.sh` | ветка / ahead-behind / грязные файлы по всем репо и корню |
| `workspace/bin/git/hooks/pre-commit` | хук корневого репо (`core.hooksPath` ставит `setup-local.sh`): `workspace/bin/check/all.sh`; обойти — `--no-verify` |
| `workspace/bin/agent/setup-local.sh` | личный слой: `.claude/settings.local.json` (`autoMemoryDirectory` и allow на скрипты абсолютным путём), `local/`, хук |
