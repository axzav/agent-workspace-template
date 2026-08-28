---
name: payment-sandbox
description: Поведение sandbox платёжного провайдера в локальном стеке и на stage
metadata: { type: project }
---
Sandbox провайдера отвечает до 30 с и периодически 502; воспроизводимо у всех. В acceptance-тестах провайдер
мокается (`backend/tests/Support/FakePaymentGateway.php`), в воркерах — ретраи с backoff (BKL-0005).
