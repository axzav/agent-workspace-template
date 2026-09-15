# infra — инструкции для агента


## Рамка репозитория
Здесь живут: `compose.yaml`, `nginx/`, `Makefile` (up/down/ps/logs/smoke/bootstrap), `keys/` (dev-ключи JWT), `.env.example`.
Здесь НЕ живут: Dockerfile сервисов (в их репо), прикладные команды, знания.
`compose.yaml` монтирует `../backend`, `../frontend`, `../realtime` по точным путям — имена папок значимы.

## Правила
- Порты и hostnames — только через `.env` (`WEBSERVER_PORT`, по умолчанию 8080); менять — вместе с `project.yaml` в корне.
- `make smoke` — curl по всем адресам; это определение «стек работает».
- Правки деплоя (`deploy/`) — только по задаче с явным упоминанием stage/prod.

## Команды
`make up | down | ps | logs service=<name> | smoke | bootstrap`.
