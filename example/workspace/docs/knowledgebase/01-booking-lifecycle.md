# Жизненный цикл бронирования
Источник истины — `backend/src/Booking/Domain/BookingStatus.php` и переходы в `BookingStateMachine`. Сверено 2026-08-20.

| UC | Переход | Кто |
|---|---|---|
| UC-010 | `pending` → `confirmed` — после успешной оплаты (событие `booking.confirmed`) | система |
| UC-011 | `pending` → `expired` — оплата не пришла за 15 минут | воркер `ExpirePendingBookings` |
| UC-012 | `confirmed` → `cancelled` — по правилам отмены (см. `02-cancellation-and-refunds.md`) | гость / хост / поддержка |
| UC-013 | `confirmed` → `completed` — на следующий день после check-out; открывает отзыв | воркер |

Даты `pending`-брони блокируются в календаре хоста (баг в UI — `workspace/tracker/notes/bugs.md`).
