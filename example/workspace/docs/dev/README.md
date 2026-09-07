# Разработка (командный способ)
- Стек: `cd infra && make up`; `make ps`, `make logs service=backend`, `make down`. Compose-project `bookly`.
- Адреса: app `:8080`, api `:8080/api`, ws `:8080/ws`; Postgres `5432`, RabbitMQ UI `15672`, Mailpit `8025`.
- Команды сервисов — через `make` сервиса в контейнере (`cd backend && make test`). На хосте — только `docker`, `git`,
  и исключения: `frontend: make e2e` (Playwright), `infra: make smoke`.
- Платежи локально — sandbox провайдера; ключи в `infra/.env.example` (тестовые). Реальные ключи — только на stage/prod.
- Окружения: local · stage (`stage.bookly.example.com`, владелец — DevOps) · prod. Ничего на stage/prod без просьбы.
- Мой способ запуска — `AGENTS.md` корня и `<сервис>/CLAUDE.local.md`; устройство личного слоя — `local-layer.md` (как в скелетоне).
