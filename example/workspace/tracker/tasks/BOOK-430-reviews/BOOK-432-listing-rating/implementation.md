# BOOK-432 — реализация

Живой документ: заполняется при разборе кода и дополняется во время работы. Продуктовые правила — в
`BOOK-432-listing-rating.md`, здесь их не повторяем.

## Где в системе
| Что | Где |
|---|---|
| Выдача поиска | `backend/src/Search/Application/SearchListingsHandler.php`, читает проекцию `listing_search` |
| Карточка объекта | `backend/src/Listing/Application/GetListingHandler.php` |
| Проекции по событиям | `backend/src/Shared/Projection/*`, образец — `ListingSearchProjector` |
| Событие отзыва | `review.published` / `review.edited` — контракт из BOOK-431 (`workspace/docs/contracts/`) |
| Фронт: карточка и выдача | `frontend/src/features/listing/Card.tsx`, `frontend/src/features/search/ResultItem.tsx` |

## Как реализуем
- Рейтинг храним денормализованно: в `listing_search` (для выдачи) и `listing` (для карточки) добавляем
  `rating numeric(2,1) null`, `reviews_count int not null default 0`. `null` = порог не достигнут.
- Пересчёт — проектор `ListingRatingProjector` на события `review.published|edited|deleted`: один запрос
  `avg + count` по опубликованным отзывам объекта, апдейт двух таблиц. Не инкремент/декремент — среднее при правке
  инкрементом не пересчитать честно.
- Порог 3 применяем при записи (`rating = null`, если count < 3), чтобы фронт не знал про правило.
- Миграция: команда `listing:rating:rebuild [--listing=]` — тот же проектор по всем объектам; нужна и для
  восстановления после сбоев.

## План
1. Миграция колонок + команда rebuild (backend).
2. Проектор + подписка на события; acceptance на таблицу из главного файла.
3. Поле `rating`/`reviewsCount` в ответах `GET /api/search`, `GET /api/listings/{id}` (аддитивно).
4. Фронт: бейдж в карточке и выдаче.
5. Замер p95 поиска на stage до/после.

## Риски и открытые технические вопросы
- Проекция `listing_search` обновляется асинхронно через очередь — при отставании очереди рейтинг отстанет
  от «минуты». Мониторинг лага очереди уже есть; отдельно ничего не делаем, но критерий «минута» проверять при
  пустой очереди.
- Правка отзыва после закрытия окна 48 ч (BOOK-431) невозможна, но событие `review.edited` может прийти от
  поддержки — проектор обрабатывает его так же.

## Журнал
(пусто — задача не начата)
