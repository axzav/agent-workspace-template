---
id: BKL-0000
type: task
title: Инициализировать слой агента из agent-workspace-template
status: done
priority: now
size: S
estimation: ""
repos: []
depends: []
remote: ""
remote_synced: ""
created: 2026-07-25 10:12
closed: 2026-07-26 17:40
---

## Контекст / Проблема
Проект ведётся из общего корня четырёх репо, но у агента нет ни карты проекта, ни трекера — каждую сессию
контекст собирается заново.

## Что делаем
Развернуть скелетон шаблона, заполнить `project.yaml`, `AGENTS.md` корня и сервисов.

## Критерии готовности
- [x] `workspace/bin/check/all.sh` зелёный.

