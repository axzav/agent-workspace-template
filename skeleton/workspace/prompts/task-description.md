# /task-description <ID> — описание задачи для удалённого трекера
Постановка пишется по `workspace/tracker/TEMPLATE-task.md` одинаково для любого режима: Контекст / Что делаем / Не
входит / Критерии готовности — продуктовым языком, без путей, классов и локальных ссылок; задачи — по ключу.
Прогнать `workspace/bin/tracker/trk.sh publish <ID> --diff`, показать diff (только осмысленные правки), после
подтверждения — `--json` → инструмент редактирования из `tracker.remote_transport` → `remote_synced` = `trk.sh now`.
Нормализатор — `workspace/tracker/AGENTS.md`, «Публикация».
