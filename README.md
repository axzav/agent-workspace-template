# agent-workspace-template — шаблон корня проекта для работы с AI-агентами

Единый формат для проектов, над которыми работа ведётся из общего корня: несколько git-репо сервисов, monorepo
с модулями или одно приложение. Шаблон самодостаточен: этот репо клонируется один раз, новые проекты создаются `init.sh`.

## Ключевые идеи
1. **Корень проекта — git-репо слоя агента** (папка называется как угодно). `.gitignore` — белый список: репо
   с кодом, склонированные внутрь, автоматически вне git. Никаких симлинков и генерации.
2. **Точка входа** — `AGENTS.md` (содержание) + `CLAUDE.md` = `@AGENTS.md`. Так же в каждом репо с кодом.
3. **Слой агента — личный целиком** (локальный git, команде не показывается), поэтому корневого `CLAUDE.local.md`
   нет — правила живут прямо в `AGENTS.md`. Личное относительно **команды** — `<сервис>/CLAUDE.local.md`
   (переопределения командных инструкций; заготовка — `repo-template/CLAUDE.local.md.example`),
   `.claude/settings.local.json`, `local/` — вне git (в сервисах — их `.gitignore` или `.git/info/exclude`).
4. **Знания (`workspace/docs`) отдельно от работы (`workspace/tracker`)**, истина по поведению — код. Матрица
   «что изменилось → куда писать».
5. **Трекер — файлы с frontmatter**, папки по «температуре», эпик — папка с контекстом, дашборд из скрипта.
   Режим `remote` — публикация тела задачи через `trk.sh publish` (нормализация, id → ключи, diff).
6. **Всё внутри папки проекта**: скиллы (внешние — копиями через `toolkit-sync.sh`), память (`workspace/memory`).
7. **Пути от корня проекта** в слое агента; внутри репо сервисов — от корня сервиса.
8. `project.yaml` — манифест, которым питаются скрипты и сверяется карта: `kind` (services | monorepo | app),
   репо с **командами качества** (`commands: test/lint/bench/smoke` — скрипты и промпты не угадывают их по Makefile)
   и **модулями** (`modules` — внутренние границы monorepo, сверяются с таблицей в `AGENTS.md`).

## Состав
```
init.sh             фаза 1: развернуть skeleton/ в корень проекта (существующие файлы не трогает);
                    4-й аргумент — режим трекера (local по умолчанию | remote): в local команды удалённого
                    трекера (/task, /tracker-pull, /tracker-comment, /task-description, /fix-mr) не ставятся
SEED.md             фаза 2: промпт агенту — заполнить карту, манифест, правила, AGENTS.md сервисов по example/;
                    путь A (репо есть) и путь B (greenfield: только концепт-доки)
SEED-DOCS.md        отдельная команда: наполнить базу знаний по коду (по областям)
skeleton/           сам шаблон (плейсхолдеры {{PROJECT}}, {{TASK_PREFIX}}, {{TRACKER_MODE}}, {{…}}); skeleton/_claude → .claude
example/            заполненный пример — проект Bookly (сервис бронирования, kind: services, remote-трекер): эталон для SEED
repo-template/      заготовки для репо сервиса: AGENTS.md, CLAUDE.md, CLAUDE.local.md.example, gitignore.snippet
MIGRATION.md        как перевести существующий проект
.claude/skills/seed скилл /seed (обёртка над SEED.md / SEED-DOCS.md)
```

## Новый или существующий проект
```bash
mkdir myshop && cd myshop                       # или существующий корень
git clone … backend; git clone … frontend; git clone … infra     # или ничего, если кода ещё нет
git clone <url> agent-workspace-template        # клон шаблона лежит в корне и остаётся там (для /seed и обновлений)
agent-workspace-template/init.sh myshop MYS . remote   # фаза 1: скелетон; local (по умолчанию) — без команд удалённого трекера
claude                                          # из корня
> /seed          # или: «прочитай agent-workspace-template/SEED.md и выполни»
> /seed docs бронирования                       # позже, по областям — база знаний
workspace/bin/agent/setup-local.sh && workspace/bin/check/all.sh
git add -A && git commit -m "workspace: init"
```
Агент из корня видит и репо сервисов, и шаблон с примером — никаких `--add-dir` и абсолютных путей. Шаблон можно
править прямо в проекте и пушить в общий репо для других проектов. Описание корня для людей — в `AGENTS.md`
(отдельный `README.md` скелетон не создаёт).

## Ежедневно
`/next-task` → `/task-done` (локальные задачи), `/tracker-add`, `/refine`, `/triage`, `/tracker-check`, `/estimate`,
`/healthcheck`; в remote-режиме ещё `/task` → `/task-done`, `/tracker-pull`, `/tracker-comment`, `/fix-mr` — шимы
в `.claude/commands`, тела в `workspace/prompts`. `workspace/bin/git/status.sh` — состояние всех репо,
`workspace/bin/stack/cmd.sh test|lint|bench|smoke [repo]` — команды качества из манифеста.
