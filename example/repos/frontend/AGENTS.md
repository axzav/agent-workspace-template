# frontend — инструкции для агента

> Карта проекта и трекер — в родительской папке (`../AGENTS.md`). Пути здесь — от корня этого репозитория.

## Что это
SPA гостя и хоста: поиск, бронирование, оплата, календарь хоста, уведомления (WebSocket). Долг: reconnect WS.

## Запуск и команды — ТОЛЬКО в контейнере
Контейнер `frontend` из `../infra` поднимает Vite с HMR — отдельный `yarn dev` не нужен. `make lint` (tsc + eslint),
`make test` (vitest), `make e2e` (Playwright — **исключение, запускается на хосте**). Не запускать node/yarn на хосте.

## Стек
React 19 · Vite · TypeScript · Tailwind · TanStack Query · Playwright.

## Архитектура и структура
`src/features/<feature>/{api,ui,model}`; API-клиент генерируется из OpenAPI backend (`make api-gen`) — руками не править.
WS-клиент — `src/shared/realtime/`.

## Правила кода
Без `any`; компоненты — функции; серверное состояние — только через TanStack Query; `data-testid` на интерактивных элементах.

## Тестирование
vitest для model/ui; Playwright для сквозных сценариев (бронирование, отмена).

## Git
База — `main`; `feat(BOOK-NNN): …`; спросить перед коммитом; push — только по просьбе (прецедент: подагент запушил в `main` — запрет push передавать подагентам).

## Чеклист «когда меняешь код»
- [ ] `make lint` зелёный
- [ ] изменился API → `make api-gen`
- [ ] сквозной сценарий обновлён
