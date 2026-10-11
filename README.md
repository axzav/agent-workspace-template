# agent-workspace-template — шаблон корня проекта для работы с AI-агентами

Единый формат для проектов, над которыми работа ведётся из общего корня: один репозиторий кода (monorepo, приложение)
или несколько репо сервисов; один человек или команда; локальный трекер или удалённый. Шаблон самодостаточен: этот репо
клонируется в корень проекта один раз, слой разворачивается `init.sh` по **профилю** и дозаполняется агентом (`/seed`).

Коротко об устройстве: корень проекта — личный git-репо слоя агента, репо кода клонируются внутрь и остаются вне его;
точка входа — тонкий `AGENTS.md`; знания (`workspace/docs`) отдельно от работы (`workspace/tracker`), истина по
поведению — код; трекер — файлы с frontmatter и скрипт-дашборд; профили вместо мёртвого кода; `project.yaml` — данные
для скриптов, не документ для агента. Почему так и по каким правилам править скелет — `PRINCIPLES.md`.

## Профиль проекта
`init.sh` спрашивает и пишет `project.yaml: profile`: `kind` (`services` | `monorepo` | `app`), `team` (`solo` | `team`),
`tracker` (`local` | `remote`), `commit` (`auto` | `ask`), `adr` (`yes` | `no`). Что означает каждый ключ — комментарии
в `skeleton/project.yaml`; какие файлы ставятся при каком ответе — `init/profiles.txt`; текст с ветвлением — директивы
`{{#if …}}` в файлах скелета (`init/render.py`). Поменять профиль позже — править `project.yaml: profile` и запустить
`init.sh` ещё раз: он доложит недостающие файлы, существующие не трогает; ставшие лишними — удалить руками.

## Состав
```
init.sh             фаза 1: развернуть skeleton/ в корень по профилю (флаги или вопросы; повторный запуск — доложить);
                    init.sh render <файл> — отрендерить файл repo-template/ по профилю проекта
init/               render.py (подстановки и {{#if}}), profiles.txt (файл → условие)
sync.sh             развёрнутый слой ↔ шаблон: status/diff — расхождения по профилю, pull — изменения шаблона в проект,
                    push — правки проекта в skeleton/ (трёхстороннее слияние от маркера project.yaml: template), mark
SEED.md             фаза 2: промпт агенту — заполнить карту, манифест, правила, AGENTS.md репо по example/;
                    путь A (репо есть), путь B (greenfield: только концепт-доки), перенос существующего проекта
SEED-DOCS.md        отдельная команда: наполнить базу знаний по коду (по областям)
PRINCIPLES.md       принципы устройства инструкций и доков, по которым собран шаблон (из рефактора живого проекта)
skeleton/           сам шаблон (плейсхолдеры {{PROJECT}}, {{TASK_PREFIX}}, {{REPO}}, {{…}} для SEED; _claude → .claude,
                    _gitignore → .gitignore при рендере)
example/            заполненный пример — проект Bookly (kind: services, team, remote-трекер): эталон для SEED;
                    его трекер проходит trk.sh check (self-test ниже)
repo-template/      заготовки для репо кода: AGENTS.md, CLAUDE.md, CLAUDE.local.md.example, gitignore.snippet,
                    docs/README.md (карта «код → техдок»), scripts/check-docs.sh (гейт ссылок и свежести техдоков)
.claude/skills/seed скилл /seed (обёртка над SEED.md / SEED-DOCS.md)
```

## Новый или существующий проект
```bash
mkdir myshop && cd myshop                       # или существующий корень
git clone … backend; git clone … frontend       # или ничего, если кода ещё нет
git clone <url> agent-workspace-template        # клон шаблона лежит в корне и остаётся там (для /seed и обновлений)
agent-workspace-template/init.sh .              # фаза 1: вопросы профиля → скелет; или флагами:
#   agent-workspace-template/init.sh . --name myshop --prefix MYS --kind services --team team --tracker remote --commit ask
claude                                          # из корня
> /seed          # или: «прочитай agent-workspace-template/SEED.md и выполни»
> /seed docs бронирования                       # позже, по областям — база знаний
workspace/bin/agent/setup-local.sh && workspace/bin/check/all.sh
git add -A && git commit -m "workspace: init"
```
Агент из корня видит и репо, и шаблон с примером — никаких `--add-dir` и абсолютных путей. Существующий проект со
старым слоем — тот же путь плюс раздел «Существующий проект» в `SEED.md`. Шаблон можно править прямо в проекте и
пушить в общий репо для других проектов (`sync.sh push`). Описание корня для людей — в `AGENTS.md` (отдельный
`README.md` скелет не создаёт).

## Обновление слоя и возврат правок в шаблон
Клон шаблона лежит в корне проекта; точка последней сходимости — `project.yaml: template` (`commit` шаблона,
`project_commit` корня; пишет `init.sh` и `sync.sh mark`). `sync.sh status` — что расходится (проектные файлы вроде
`AGENTS.md`, манифеста и карт доков не сверяются; свои добавить в `template.skip`); `sync.sh pull` — дельта шаблона с
маркера сливается в файлы проекта, специализация (имя репо, термины продукта) сохраняется; `sync.sh push` — правки
проекта с маркера сливаются в `skeleton/`, дальше обобщить руками (`{{REPO}}`, общие термины, `{{#if}}` по профилю) и
закоммитить шаблон. Конфликты — маркеры `<<<<<<<` в файле, код 1, маркер не двигается. В Claude Code всё это делает
`/template-sync`: гоняет скрипт, разбирает конфликты, обобщает формулировки, обновляет `PRINCIPLES.md`.

Self-test шаблона после правки скелета: `init.sh` в пустую папку с профилем проекта и `sync.sh status` оттуда — 0
расхождений; скелет, отрендеренный по профилю `example/` поверх его копии, — `trk.sh check` зелёный под `/bin/bash`
(macOS bash 3.2: имя переменной перед `»` писать как `${v}»`).

## Ежедневно
`/next-task [ID|KEY]` (взять или продолжить, сделать, сдать), `/tracker-add`, `/refine [текст]`, `/template-sync`;
по профилю — `/adr`, `/tracker-pull`, `/tracker-comment`, `/task-description` — шимы в `.claude/commands`, тела в
`workspace/prompts`. Скрипты — `workspace/bin/README.md`: `git/status.sh` — состояние всех репо, `stack/cmd.sh
<команда> [repo]` — команды качества из манифеста, `stack/healthcheck.sh` — проверки стека сервисов, `check/all.sh` —
проверки слоя (и хук pre-commit).
