# backend — инструкции для агента

> Карта проекта, трекер и знания — в родительской папке (`../AGENTS.md`); агент обычно запускается оттуда.
> Пути здесь — от корня этого репозитория. Личные переопределения — `CLAUDE.local.md` (не в git).

## Что это
REST API Bookly и весь домен (Listing, Booking, Payment, Review) + воркеры RabbitMQ (письма, возвраты).
Реализовано: listings, bookings, отмена с расчётом возврата (в работе), платежи через провайдера. Долг: отчёты хоста.

## Запуск и команды — ТОЛЬКО в контейнере
Стек поднимает `../infra` (`make up`). Здесь: `make sh`, `make test` (unit), `make acc` (acceptance, `c='features/...'`),
`make lint` (php-cs-fixer + phpstan), `make migrate`, `make sf c='...'`. На хосте не запускать php/composer.

## Стек
Symfony 7.1 · PHP 8.3 · PostgreSQL 16 · Redis · RabbitMQ · Doctrine ORM/Migrations · Behat (acceptance).

## Архитектура и структура
Модульный монолит, DDD-слои: `src/<Module>/{Domain,Application,Infrastructure,Http}`. Кросс-модульно — только через
Application-сервисы и события. Исходящие события — через Outbox (`src/Shared/Outbox`).

| Область | Док |
|---|---|
| Аутентификация (JWT RS256) | `docs/auth.md` |
| События и Outbox | `docs/events.md` |
| БД и миграции | `docs/database.md` |

## Правила кода
Value Objects для денег (`Money`), никакого float; контроллеры без бизнес-логики; репозитории — интерфейсы в Domain.

## Тестирование
Acceptance (Behat) — основные и обязательные для любого изменения поведения; unit — для домена. Контроллер-тесты
на PHPUnit не писать. Провайдер платежей — только `FakePaymentGateway`.

## Git
База — `main`; `feat(BOOK-NNN): …`; **перед коммитом спросить**; push — только по просьбе. Не редактировать
`CONTRIBUTING.md` (устарел).

## Чеклист «когда меняешь код»
- [ ] миграция + `make migrate` в чистой БД
- [ ] acceptance-сценарий на новое поведение
- [ ] событие изменилось → контракт в `../workspace/docs/contracts/` и realtime в том же изменении
- [ ] `docs/*.md` области актуален
