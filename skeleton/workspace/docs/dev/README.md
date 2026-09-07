# Разработка (командный способ)
- Стек: `{{run.team из project.yaml}}`. Адреса и порты — `project.yaml`.
- Команды качества — `project.yaml: repos[].commands` (`workspace/bin/stack/cmd.sh test|lint|bench|smoke [repo]`).
  На хосте нужны: {{только `docker` и `git` / тулчейн стека}}. Исключения: {{Playwright/e2e, smoke}}.
- Окружения: local / stage / prod — {{адреса, кто владеет}}. Ничего на stage/prod без явной просьбы.
- Мой способ запуска (если отличается от командного) — `AGENTS.md` корня и `<сервис>/CLAUDE.local.md`; устройство личного слоя — `local-layer.md`.
