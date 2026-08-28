# /tracker-add — завести задачу
Из аргумента собрать задачу по `workspace/tracker/TEMPLATE-task.md`. Id: локальный режим или задача без тикета —
`trk.sh next-id`; задача для удалённого трекера — сначала создать тикет через `tracker.remote_transport` (заголовок +
постановка), id = его ключ, `remote` = ключ, `remote_synced` = `trk.sh now`. Далее title, repos (из
`project.yaml`), size (грубо, без анализа кода; `estimation` не трогать), `created` = `trk.sh now`, epic если назван.
Разделы — по правилам `workspace/tracker/AGENTS.md` («Главный файл и implementation.md»). Показать файл целиком, после
подтверждения записать в `tasks/` (или в папку эпика). Сомневаешься в формате — эталоны в клоне шаблона:
`agent-workspace-template/example/workspace/tracker` (задача BOOK-431, эпик BOOK-430, вопросы BOOK-434, баг
BOOK-440); не читать их без нужды.
