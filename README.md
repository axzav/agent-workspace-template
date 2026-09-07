# agent-workspace-template — шаблон корня проекта для работы с AI-агентами

Единый формат для проектов из нескольких git-репо, над которыми работа ведётся из общего корня.
Шаблон самодостаточен: этот репо клонируется один раз, новые проекты создаются `init.sh`.

## Ключевые идеи
1. **Корень проекта — git-репо слоя агента** (папка называется как угодно). `.gitignore` — белый список: репо сервисов,
   склонированные внутрь, автоматически вне git. Никаких симлинков и генерации.
2. **Точка входа** — `AGENTS.md` (содержание) + `CLAUDE.md` = `@AGENTS.md`. Так же в каждом сервисе.
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
8. `project.yaml` — манифест, которым питаются скрипты и сверяется карта.

## Состав
```
init.sh             фаза 1: развернуть skeleton/ в корень проекта (существующие файлы не трогает)
SEED.md             фаза 2: промпт агенту — заполнить карту, манифест, правила, AGENTS.md сервисов по example/
SEED-DOCS.md        отдельная команда: наполнить базу знаний по коду (по областям)
skeleton/           сам шаблон (плейсхолдеры {{PROJECT}}, {{TASK_PREFIX}}, {{…}}); skeleton/_claude → .claude
example/            заполненный пример — проект Bookly (сервис бронирования): эталон для SEED
repo-template/      заготовки для репо сервиса: AGENTS.md, CLAUDE.md, gitignore.snippet
MIGRATION.md        как перевести существующий проект
.claude/skills/seed скилл /seed (обёртка над SEED.md / SEED-DOCS.md)
```

## Новый или существующий проект
```bash
mkdir myshop && cd myshop                       # или существующий корень
git clone … backend; git clone … frontend; git clone … infra
git clone <url> agent-workspace-template        # клон шаблона лежит в корне и остаётся там (для /seed и обновлений)
agent-workspace-template/init.sh myshop MYS .   # фаза 1: скелетон (в .gitignore корня клон шаблона игнорируется сам)
claude                                          # из корня
> /seed          # или: «прочитай agent-workspace-template/SEED.md и выполни»
> /seed docs бронирования                       # позже, по областям — база знаний
workspace/bin/agent/setup-local.sh && workspace/bin/check/all.sh
git add -A && git commit -m "workspace: init"
```
Агент из корня видит и репо сервисов, и шаблон с примером — никаких `--add-dir` и абсолютных путей. Шаблон можно
править прямо в проекте и пушить в общий репо для других проектов.

## Ежедневно
`/task` → `/task-done` (remote-трекер), `/next-task` (локальные задачи), `/tracker-add`, `/tracker-pull`,
`/tracker-comment`, `/refine`, `/triage`, `/tracker-check`, `/healthcheck` — шимы в `.claude/commands`,
тела в `workspace/prompts`. `workspace/bin/git/status.sh` — состояние всех репо.
