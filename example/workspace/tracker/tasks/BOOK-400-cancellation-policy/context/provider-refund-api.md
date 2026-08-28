# Выдержка из API провайдера: возвраты (устаревает, актуально — их документация)
`POST /v1/refunds` — тело `{payment_id, amount, idempotency_key}`; ответ `202` и `refund_id`; статус — по вебхуку
`refund.succeeded|failed` (до 30 с). Повтор с тем же `idempotency_key` — тот же `refund_id`. Лимит: 10 запросов/с.
