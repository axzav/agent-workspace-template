---
id: BKL-0001
type: task
title: Примеры авторизации в Swagger backend
status: todo
priority: normal
size: S
estimation: ""
repos: [backend]
depends: []
remote: ""
remote_synced: ""
created: 2026-08-10 09:30
closed: ""
---

## Контекст / Проблема
В `/api/doc` нет примера получения JWT — каждый новый разработчик спрашивает в чате, как авторизоваться.

## Что делаем
В описание OpenAPI добавить пример запроса `POST /api/auth/token` и заголовка `Authorization`; в Swagger должна
работать кнопка «Authorize» с этим примером.

## Критерии готовности
- [ ] В Swagger есть блок «Authorize» с рабочим примером.
- [ ] `backend/docs/auth.md` ссылается на него.

