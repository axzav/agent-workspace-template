# Idempotency-Key на POST /bookings/{id}/cancel
Где: `backend/src/Booking/Http/CancelController.php`. Почему: двойной клик в UI создаёт две отмены и два события
`booking.cancelled`; воркер возврата дедупит по booking_id, но realtime показывает два уведомления. Размер: S.
Найдено в BOOK-412, в её скоуп не входит.
