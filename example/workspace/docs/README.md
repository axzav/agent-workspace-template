# docs/ — индекс знаний Bookly

| Папка/файл | Владеет | Когда читать |
|---|---|---|
| `knowledgebase/01-booking-lifecycle.md` | статусы брони, кто и когда может менять | любая задача про бронирования |
| `knowledgebase/02-cancellation-and-refunds.md` | политика отмены, расчёт возврата (UC-020…UC-024) | эпик BOOK-400 |
| `contracts/events/` | события `booking.*` — JSON Schema + фикстуры | правка backend↔realtime↔workers |
| `dev/README.md` | командный стек, sandbox платежей, окружения | запуск/диагностика |

## Матрица «что изменилось → куда писать»
| Изменилось | Править |
|---|---|
| Правило отмены/возврата, статусы | `knowledgebase/02-…` (+ код) |
| Событие `booking.*` | `contracts/events/` + backend + realtime + фикстура |
| Порты, команды, окружения | `dev/README.md`, `project.yaml` |
| Состав сервисов | `AGENTS.md` корня + `project.yaml` |
| Ход работы | `tracker/` |
