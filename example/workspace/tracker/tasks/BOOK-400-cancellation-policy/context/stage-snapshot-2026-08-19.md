# Снапшот stage 2026-08-19 (перед началом эпика)
- `CancellationPolicy` на stage — старая версия (strict 30 %), расчёта возврата нет.
- Таблица `booking_refund` отсутствует — миграция в BOOK-412.
- realtime на stage не подписан на `booking.cancelled`.
