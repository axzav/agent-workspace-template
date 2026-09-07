# Bookly — карта проекта (точка входа для агента)

Ты работаешь **из корня проекта** `bookly/`. Корень и `workspace/` — мой личный слой (локальный git): карта,
правила, знания, трекер. Репозитории сервисов лежат рядом как обычные папки и **в этот репо не входят** (`.gitignore` — белый список).
Все пути в этом файле, в `workspace/` и в `.claude/` — **от корня проекта**. Внутри репо сервисов их `AGENTS.md`
используют пути от корня сервиса — они независимы.

Слой личный целиком (локальный git, команде не показывается), поэтому «как я запускаю» и мои правила — прямо
здесь; переопределения командных инструкций сервиса — `<сервис>/CLAUDE.local.md` (не в git сервиса).

## Лестница чтения
1. Этот файл — карта и правила.
2. `workspace/tracker/AGENTS.md` — как устроен трекер (перед любой работой над задачей).
3. `<сервис>/AGENTS.md` — перед правкой кода в сервисе.
4. `workspace/docs/README.md` — индекс знаний; по мере необходимости.

## О продукте
Bookly — площадка бронирования жилья: **хост** публикует объект и календарь, **гость** ищет, бронирует и платит,
обе стороны получают уведомления в реальном времени. Ключевые сущности: Listing, Booking, Payment, Review.
Бизнес-правила — `workspace/docs/knowledgebase/`.

## Сервисы (репозитории)
Источник истины — `project.yaml`; таблица сверяется `workspace/bin/check/manifest.sh`.

| Папка | Что это | Стек | Базовая ветка | Скоуп коммитов | Статус | Док агента |
|---|---|---|---|---|---|---|
| `backend/` | REST API, домен (listings, bookings, payments), воркеры очередей | Symfony 7.1 · PHP 8.3 · PostgreSQL 16 · Redis · RabbitMQ | `main` | `feat(BOOK-NNN)` | ✅ | `backend/AGENTS.md` |
| `frontend/` | Веб-приложение гостя и хоста | React 19 · Vite · TypeScript · Tailwind | `main` | `feat(BOOK-NNN)` | ✅ | `frontend/AGENTS.md` |
| `realtime/` | WebSocket-уведомления (статусы брони, сообщения) | Node 22 · ws · Redis pub/sub | `main` | `feat(BOOK-NNN)` | 🟡 | `realtime/AGENTS.md` |
| `infra/` | Локальный стек и деплой; **инфра-правки только здесь** | docker compose · make · nginx | `main` | — | ✅ | `infra/AGENTS.md` |

Статусы: ✅ активно · 🟡 в работе/частично · ⬜ заглушка · ⚠️ устарело.
Устаревшие tracked-файлы: `backend/CONTRIBUTING.md` — описывает host-PHP и Symfony 5, **игнорировать, не редактировать**.

## Как сервисы связаны
```
frontend ──HTTP/JSON──▶ backend ──publish──▶ RabbitMQ ──▶ backend workers (email, payments)
   │                        │
   └──WebSocket──▶ realtime ◀──Redis pub/sub (booking.*, message.*)──┘
```
- Аутентификация: backend выдаёт JWT (RS256); realtime проверяет подпись публичным ключом из `infra/keys/`.
- События `booking.created|confirmed|cancelled` — контракт `workspace/docs/contracts/events/`; их публикует backend,
  потребляют воркеры и realtime. Меняется событие → меняются обе стороны и фикстура в одном изменении.
- Платежи: backend ↔ провайдер (sandbox локально, см. `workspace/docs/dev/README.md`).

## Запуск проекта (командный способ)
```bash
cd infra && make up          # весь стек; make help — список целей; make smoke — проверка адресов
```
Адреса: `http://app.bookly.local:8080` (frontend), `http://api.bookly.local:8080/api` (backend, Swagger `/api/doc`),
`ws://api.bookly.local:8080/ws` (realtime). Порты сервисов — `project.yaml: ports`.
Команды сервисов — **только через `make` сервиса внутри контейнера**; на хосте нужны только `docker` и `git`.
Исключения на хосте: `make e2e` во frontend (Playwright), `make smoke` в infra (curl).

## Правила работы
- **Работа и её история — только в `workspace/tracker/`**; знания — в `workspace/docs/`; истина по поведению — код.
  Матрица «что изменилось → куда писать» — `workspace/docs/README.md`.
- Задача может трогать несколько репо: коммить **в каждом явно** (`git -C backend …`); статус задачи, код и доки —
  **в одном изменении**.
- Коммиты — Conventional Commits со скоупом задачи: `feat(BOOK-432): …`. **Перед коммитом — спросить**; `git push` —
  только по явной просьбе; подагентам передавать запрет push.
- Инфраструктурные правки (compose, nginx, `.env`) — в `infra/`, не в сервисах.
- Ничего на stage/prod без явной просьбы. Платёжный провайдер локально — только sandbox.
- Находки «стоило бы сделать» — `workspace/tracker/proposals/`.
- Секреты — только через переменные окружения; `.mcp.json` использует `${BOOKLY_TRACKER_TOKEN}`.

## Скиллы, команды, память
- `.claude/commands/*` — тонкие шимы, тела в `workspace/prompts/`.
- `.claude/skills/*` — проектные; внешних наборов нет (`project.yaml: toolkit.sources` пуст).
- Память — `workspace/memory/`; писать только воспроизводимое у всех; есть док-владелец — писать туда.

## Скрипты воркспейса
`workspace/bin/README.md`: `git/status.sh`, `git/pull.sh`, `tracker/trk.sh`, `stack/healthcheck.sh`, `check/all.sh`.
