# SYNXIS -> RPAC -> OTDS: Бэклог Реализации

## Порядок Реализации

Если задача стоит именно как реализация системы, а не как дописывание спецификации, порядок должен быть таким:

1. контракты
2. схема базы и границы хранения
3. адаптеры к legacy-источникам данных
4. входной транспорт и получение bundle
5. канонический `HotelData`
6. сборка RPAC
7. OTDS mapping и export-ready модель
8. OTDS XML writer и жизненный цикл архива
9. read-only операционные экраны
10. редактируемые admin-формы и policy CRUD
11. observability, replay и e2e rollout

Критический принцип:

- сначала база и контракты
- потом сервисы и пайплайн
- формы делать после того, как понятны таблицы, source of truth и lifecycle

Если начать с форм раньше базы, появятся UI-решения без стабильной доменной модели.

## Порядок Рабочих Потоков

### Фаза A. Базовые Договорённости

- контракты
- состояния
- идентификаторы
- taxonomy ошибок

### Фаза B. Сначала База

- схема
- ограничения
- политика хранения
- контракты хранения

### Фаза C. Источники Данных

- hotel matching
- контракт details
- источники room/board mapping
- источники export policy

### Фаза D. Пайплайн

- input
- canonical
- build
- mapping
- export

### Фаза E. Интерфейсы И Эксплуатация

- операционные браузеры
- admin CRUD
- инструменты replay
- метрики и e2e

---

## Этап 0. Контракты И Доменные Границы

### Задача 0.1. Зафиксировать `SynxisHotelBundle`

Тип:

- spec-only

Зависит от:

- нет

Приоритет:

- P0

Оценка:

- M

Блокируется:

- нет

Блокирует:

- 0.2
- 0.7
- 0.8
- 1.1
- 3.1
- 3.4
- 3.9

Почему эта задача ранняя:

- без контракта bundle неизвестно, что именно система принимает на вход

Какие legacy-файлы изучить:

- [modules/xhotels/classes/Provider/Synxis/Command/Prices/DownloadPrices.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Command/Prices/DownloadPrices.php)
- [modules/xhotels/classes/Framework/Application/Command/Prices/AbstractDownloadDeliveryCmd.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Framework/Application/Command/Prices/AbstractDownloadDeliveryCmd.php)
- [modules/xhotels/classes/Framework/Delivery/AbstractPriceDelivery.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Framework/Delivery/AbstractPriceDelivery.php)
- [modules/xhotels/classes/Framework/Delivery/Archive/Zip.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Framework/Delivery/Archive/Zip.php)

Какая логика сейчас в legacy:

- orchestration скачивает четыре обязательных XML на один отель
- delivery-слой сразу пишет их в archive storage
- retry и finalization живут рядом с physical delivery logic
- bundle сейчас больше похож на delivery artifact, чем на доменную сущность

Что сделать:

1. Зафиксировать точный контракт из 4 файлов.
2. Зафиксировать поля bundle и его метаданные.
3. Зафиксировать статусы bundle.
4. Зафиксировать правило неизменяемости.
5. Зафиксировать семантику checksum и дедупликации.

Что должно получиться:

- финальный контракт bundle
- финальный список validation-статусов
- пример валидного bundle

### Задача 0.2. Зафиксировать `HotelData`

Тип:

- spec-only

Зависит от:

- 0.1

Приоритет:

- P0

Оценка:

- L

Блокируется:

- 0.1

Блокирует:

- 0.3
- 0.5
- 0.7
- 1.2
- 4.4
- 4.5

Какие legacy-файлы изучить:

- [modules/xhotels/classes/Provider/Synxis/Rpac/HotelData/HotelDataFactory.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/HotelData/HotelDataFactory.php)
- [modules/xhotels/classes/Provider/Synxis/Rpac/HotelData/HotelData.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/HotelData/HotelData.php)
- [modules/xhotels/classes/Provider/Synxis/Rpac/ContractDataProvider.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/ContractDataProvider.php)

Какая логика сейчас в legacy:

- одна factory одновременно парсит XML и применяет business enrichment
- объект hotel data уже несёт несколько разных концептов: rooms, boards, rate plans, currency, descriptive room list, age semantics
- внешний mapping provider уже на этом этапе влияет на canonical board resolution

Что сделать:

1. Зафиксировать обязательные поля.
2. Зафиксировать инварианты.
3. Зафиксировать связи между rooms/rate plans/boards.
4. Зафиксировать выходную age-semantics модель.
5. Зафиксировать выходные occupancy-ограничения.

Что должно получиться:

- финальный контракт `HotelData`
- канонический пример snapshot

### Задача 0.3. Зафиксировать `RpacBuildResult`

Тип:

- spec-only

Зависит от:

- 0.2, 0.5, 0.7

Приоритет:

- P0

Оценка:

- L

Блокируется:

- 0.2
- 0.5
- 0.7

Блокирует:

- 0.4
- 0.7
- 0.8
- 1.5
- 5.1

Какие legacy-файлы изучить:

- [modules/xhotels/classes/Provider/Synxis/Rpac/RpacBuilder.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/RpacBuilder.php)
- [modules/xhotels/classes/Provider/Synxis/Rpac/InventoriesProcessor.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/InventoriesProcessor.php)
- [modules/xhotels/classes/Provider/Synxis/Rpac/AvailabilitiesProcessor.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/AvailabilitiesProcessor.php)
- [modules/xhotels/classes/Provider/Synxis/Rpac/RatesProcessor.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/RatesProcessor.php)

Какая логика сейчас в legacy:

- builder и processors вместе создают итоговую RPAC-структуру
- processors логически разделены по ответственности, но финальный контракт не зафиксирован формально
- warnings и reject-cases существуют семантически, но не оформлены как одна нормализованная result-model

Что сделать:

1. Зафиксировать формы hotel/offer/intersection.
2. Зафиксировать формы `RpacPrice` и `RpacAvailability`.
3. Зафиксировать секции `warnings`, `rejects`, `stats` в результате.
4. Зафиксировать детерминированный порядок обработки.

Что должно получиться:

- финальный build-контракт
- один happy-path snapshot сборки

### Задача 0.4. Зафиксировать `ExportReadyHotel`

Тип:

- spec-only

Зависит от:

- 0.3, 0.5, 0.6

Приоритет:

- P0

Оценка:

- M

Блокируется:

- 0.3
- 0.5
- 0.6

Блокирует:

- 0.7
- 0.8
- 1.3
- 1.4
- 1.6
- 2.5
- 7.1

Какие legacy-файлы изучить:

- [modules/otds/src/Hotels/HotelCandidate.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/HotelCandidate.php)
- [modules/otds/src/Hotels/ExportedHotel.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/ExportedHotel.php)

Какая логика сейчас в legacy:

- hotel candidate накапливает room info, board info, master data и compiler collection до создания финального export object
- candidate изменяемый и может быть rejected во время preparation
- exported hotel является финальным объектом writer-слоя

Что сделать:

1. Зафиксировать поля export-ready hotel.
2. Зафиксировать поля mapped room.
3. Зафиксировать поля mapped board.
4. Зафиксировать финальную структуру combinations.
5. Зафиксировать пустые и rejected export-ready кейсы.

Что должно получиться:

- финальный контракт `ExportReadyHotel`
- один пример export-ready snapshot

### Задача 0.5. Зафиксировать правила идентификаторов

Тип:

- spec-only

Зависит от:

- 0.2

Приоритет:

- P0

Оценка:

- M

Блокируется:

- 0.2

Блокирует:

- 0.3
- 0.4
- 1.2
- 1.3
- 1.4
- 2.2
- 2.3
- 2.4
- 2.6
- 5.4

Какие legacy-файлы изучить:

- [modules/xhotels/classes/Provider/Synxis/Rpac/RpacBuilder.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/RpacBuilder.php)
- [modules/xhotels/classes/Provider/Synxis/Rpac/HotelData/HotelData.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/HotelData/HotelData.php)
- [modules/otds/src/Hotels/Preparation/RoomsInfo/InfoProvider.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/Preparation/RoomsInfo/InfoProvider.php)
- [modules/otds/src/Hotels/Preparation/BoardsInfo/InfoProvider.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/Preparation/BoardsInfo/InfoProvider.php)

Какая логика сейчас в legacy:

- provider room code позже превращается в canonical/suffixed room identity
- идентификатор board не приходит из одного прямого raw export field; он резолвится через mapping
- export preparation уже ожидает заранее стабилизированные identifiers

Что сделать:

1. Зафиксировать идентификатор provider room.
2. Зафиксировать канонический идентификатор room.
3. Зафиксировать идентификатор board.
4. Зафиксировать идентификатор offer.
5. Зафиксировать момент фиксации неизменяемости идентификатора.

### Задача 0.6. Зафиксировать External Code Source Of Truth

Тип:

- spec-only

Зависит от:

- нет

Приоритет:

- P0

Оценка:

- S

Блокируется:

- нет

Блокирует:

- 0.4
- 2.1
- 2.5
- 6.1
- 9.1
- 9.3

Какие legacy-файлы изучить:

- [modules/otds/src/Hotels/HotelsSelector.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/HotelsSelector.php)
- [modules/otds/src/Hotels/HotelCandidate.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/HotelCandidate.php)
- [modules/xadmin/application/modules/zhotels/forms/Overview.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/zhotels/forms/Overview.php)
- [modules/xadmin/classes/Hotel/Db/TableRelations/HotelMatching.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/Db/TableRelations/HotelMatching.php)
- [modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Forms/AbstractForm.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Forms/AbstractForm.php)

Какая логика сейчас в legacy:

- exporter выбирает candidates из `hotel_matching`
- `HotelCandidate` требует непустой `external_code`
- export policy records используют `external_hotel_code` как lookup key, а не как мастер-идентификатор

Что сделать:

1. Зафиксировать `hotel_matching.external_code` как master source.
2. Зафиксировать семантику lookup для export-policy.
3. Зафиксировать зависимость export selection от hotel status и export flags.

### Задача 0.7. Зафиксировать taxonomy ошибок и reject-сценариев

Тип:

- spec-only

Зависит от:

- 0.1, 0.2, 0.3, 0.4

Приоритет:

- P0

Оценка:

- M

Блокируется:

- 0.1
- 0.2
- 0.3
- 0.4

Блокирует:

- 0.3
- 1.7
- 2.6
- 3.8
- 3.9
- 5.1
- 5.3
- 5.10
- 8.3
- 10.5

Какие legacy-файлы изучить:

- [modules/xhotels/classes/Provider/Synxis/Events/AdultAgeWasNotResolved.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Events/AdultAgeWasNotResolved.php)
- [modules/xhotels/classes/Provider/Synxis/Events/InconsistentRoomsDelivered.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Events/InconsistentRoomsDelivered.php)
- [modules/xhotels/classes/Provider/Synxis/Events/MinChildAgeIsNotDefined.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Events/MinChildAgeIsNotDefined.php)
- [modules/xhotels/classes/Provider/Synxis/Exceptions/SynxisClientException.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Exceptions/SynxisClientException.php)
- [modules/xhotels/classes/Provider/Synxis/APSClient/APSClient.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/APSClient.php)

Какая логика сейчас в legacy:

- transport-ошибки приходят как исключения
- business quality problems проявляются как события или отбрасывания на поздних этапах
- эти две семьи проблем не нормализованы в одну устойчивую taxonomy

Что сделать:

1. Разделить error families.
2. Зафиксировать machine-readable коды.
3. Зафиксировать матрицу retryability.
4. Зафиксировать scope каждого reject.

### Задача 0.8. Зафиксировать state machine по ключевым сущностям

Тип:

- spec-only

Зависит от:

- 0.1, 0.3, 0.4

Приоритет:

- P0

Оценка:

- M

Блокируется:

- 0.1
- 0.3
- 0.4

Блокирует:

- 1.1
- 1.5
- 1.6

Что сделать:

1. Зафиксировать lifecycle bundle.
2. Зафиксировать lifecycle RPAC.
3. Зафиксировать lifecycle export.
4. Зафиксировать поведение replay/versioning.

---

## Этап 1. Сначала База И Хранение

### Задача 1.1. Спроектировать таблицу `synxis_hotel_bundle`

Тип:

- db

Зависит от:

- 0.1, 0.8

Приоритет:

- P0

Оценка:

- L

Блокируется:

- 0.1
- 0.8

Блокирует:

- 1.8
- 3.7
- 4.1
- 8.1

Какая логика сейчас в legacy:

- bundle сейчас существует как archive artifact и неявная storage-концепция, а не как отдельная first-class table

Что сделать:

1. Зафиксировать колонки.
2. Зафиксировать уникальный ключ.
3. Зафиксировать статусные поля.
4. Зафиксировать стратегию checksum.
5. Определить хранение payload vs path.

Что должно получиться:

- черновик DDL
- индексы
- заметки по retention

### Задача 1.2. Спроектировать таблицу `provider_rateplan_board_mapping`

Тип:

- db

Зависит от:

- 0.2, 0.5

Приоритет:

- P0

Оценка:

- M

Блокируется:

- 0.2
- 0.5

Блокирует:

- 1.8
- 2.2
- 9.2

Какие legacy-файлы изучить:

- [lib/classlib/Db/Hotel/Tables/SynxisContractDetails.php](/home/d.shein/Projects/xres_git/lib/classlib/Db/Hotel/Tables/SynxisContractDetails.php)
- [lib/classlib/Hotel/SynXis/DataProvider/ContractDetails.php](/home/d.shein/Projects/xres_git/lib/classlib/Hotel/SynXis/DataProvider/ContractDetails.php)

Какая логика сейчас в legacy:

- legacy table already stores hotel + environment + rate_code + meal_plan
- data provider uses it as `rate -> board` lookup source for one hotel and one environment

Что сделать:

1. Сопоставить старые колонки с greenfield-смыслом.
2. Зафиксировать уникальность.
3. Зафиксировать scope по environment.
4. Зафиксировать admin ownership.

### Задача 1.3. Спроектировать таблицу `provider_room_mapping`

Тип:

- db

Зависит от:

- 0.4, 0.5

Приоритет:

- P0

Оценка:

- M

Блокируется:

- 0.4
- 0.5

Блокирует:

- 1.8
- 2.3
- 9.4

Какую legacy-логику нужно сохранить:

- OTDS export требует room metadata, которую нельзя надёжно вывести только из raw provider room code
- room mapping относится к standing-data, а не к ответственности writer-слоя

Что сделать:

1. Зафиксировать колонки и обязательные поля.
2. Зафиксировать уникальность.
3. Добавить опциональные поля `active`/validity/audit при необходимости.
4. Зафиксировать lookup-ключи.

### Задача 1.4. Спроектировать таблицу `provider_board_mapping`

Тип:

- db

Зависит от:

- 0.4, 0.5

Приоритет:

- P0

Оценка:

- M

Блокируется:

- 0.4
- 0.5

Блокирует:

- 1.8
- 2.4
- 9.5

Какую legacy-логику нужно сохранить:

- board export metadata приходит из отдельного standing-data mapping
- это отдельная сущность и её нельзя смешивать с Synxis `rate -> meal_plan` mapping

Что сделать:

1. Зафиксировать колонки.
2. Зафиксировать уникальность.
3. Зафиксировать обязательные export-атрибуты.
4. Зафиксировать lookup-ключи.

### Задача 1.5. Спроектировать таблицы хранения RPAC

Тип:

- db

Зависит от:

- 0.3, 0.8

Приоритет:

- P1

Оценка:

- XL

Блокируется:

- 0.3
- 0.8

Блокирует:

- 1.8
- 8.2

Какие таблицы входят:

- `rpac_hotels`
- `rpac_offers`
- `rpac_intersections`
- `rpac_prices`
- `rpac_availabilities`
- `rpac_filters`

Что сделать:

1. Зафиксировать структуры таблиц.
2. Зафиксировать внешние ключи.
3. Зафиксировать уникальные ключи.
4. Определить что хранится, а что пересчитывается.

### Задача 1.6. Спроектировать таблицы export run и artifacts

Тип:

- db

Зависит от:

- 0.4, 0.8

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 0.4
- 0.8

Блокирует:

- 1.8
- 7.8
- 8.4

Что сделать:

1. Спроектировать реестр export run.
2. Спроектировать метаданные xml/archive артефактов.
3. Спроектировать колонки статуса экспорта и ошибок.
4. Спроектировать связи с версией RPAC и hotel identity.

### Задача 1.7. Спроектировать хранение warnings и rejects

Тип:

- db

Зависит от:

- 0.7

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 0.7

Блокирует:

- 1.8
- 8.2
- 8.3
- 10.3

Что сделать:

1. Определить, нужен ли отдельный event table или materialized log view.
2. Зафиксировать колонки для scope, code, payload и version.
3. Зафиксировать retention-политику.

### Задача 1.8. Определить порядок миграций

Тип:

- db

Зависит от:

- 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7

Приоритет:

- P0

Оценка:

- S

Блокируется:

- 1.1
- 1.2
- 1.3
- 1.4
- 1.5
- 1.6
- 1.7

Блокирует:

- 2.1
- 9.1

Почему эта задача нужна:

- database-first реализация требует детерминированного порядка миграций до разработки форм и сервисов

Что сделать:

1. Упорядочить базовые таблицы.
2. Упорядочить mapping-таблицы.
3. Упорядочить таблицы RPAC.
4. Упорядочить операционные export-таблицы.

---

## Этап 2. Адаптеры Legacy-Источников Данных

### Задача 2.1. Реализовать read-model boundary для `HotelMatching`

Тип:

- backend

Зависит от:

- 0.6, 1.8

Приоритет:

- P0

Оценка:

- M

Блокируется:

- 0.6
- 1.8

Блокирует:

- 6.1
- 9.1
- 10.4

Какие legacy-файлы изучить:

- [modules/otds/src/Hotels/HotelsSelector.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/HotelsSelector.php)
- [modules/xadmin/classes/Hotel/Db/TableRelations/HotelMatching.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/Db/TableRelations/HotelMatching.php)

Какая логика сейчас в legacy:

- выбор зависит от `external_code`, `status`, `export`, `operator_id`, `source_market_id`
- сортировка по `external_code` семантически важна для дальнейшей группировки в writer-слое

Что сделать:

1. Реализовать явный read-адаптер.
2. Зафиксировать контракт выбора exportable hotel.
3. Зафиксировать гарантию порядка.

### Задача 2.2. Реализовать read-model boundary для `ContractDetails`

Тип:

- backend

Зависит от:

- 1.2, 0.5

Приоритет:

- P0

Оценка:

- M

Блокируется:

- 1.2
- 0.5

Блокирует:

- 4.6
- 9.2
- 10.4

Какие legacy-файлы изучить:

- [lib/classlib/Hotel/SynXis/DataProvider/ContractDetails.php](/home/d.shein/Projects/xres_git/lib/classlib/Hotel/SynXis/DataProvider/ContractDetails.php)
- [lib/classlib/Db/Hotel/Tables/SynxisContractDetails.php](/home/d.shein/Projects/xres_git/lib/classlib/Db/Hotel/Tables/SynxisContractDetails.php)

Какая логика сейчас в legacy:

- provider reads available hotel ids per environment
- provider returns `rate_code -> meal_plan` pairs for one hotel and environment

Что сделать:

1. Выделить чистый контракт для board resolution.
2. Нормализовать параметры hotel/environment.
3. Отвязать from legacy-классы таблиц.

### Задача 2.3. Реализовать Room Mapping Прочитать Model Boundary

Тип:

- backend

Зависит от:

- 1.3, 0.5

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 1.3
- 0.5

Блокирует:

- 6.3
- 9.4

Какие legacy-файлы изучить:

- [modules/otds/src/Hotels/Preparation/RoomsInfo/InfoProvider.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/Preparation/RoomsInfo/InfoProvider.php)
- [modules/otds/src/Hotels/Preparation/RoomsInfo/BasicInfoProvider.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/Preparation/RoomsInfo/BasicInfoProvider.php)

Какая логика сейчас в legacy:

- room mapping is obtained as export enrichment after RPAC already exists
- room info has both booking code and descriptive metadata role

Что сделать:

1. Реализовать lookup-контракт.
2. Реализовать структуру данных `MappedRoom`.
3. Зафиксировать поведение при отсутствии mapping.

### Задача 2.4. Реализовать Board Mapping Прочитать Model Boundary

Тип:

- backend

Зависит от:

- 1.4, 0.5

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 1.4
- 0.5

Блокирует:

- 6.4
- 9.5

Какие legacy-файлы изучить:

- [modules/otds/src/Hotels/Preparation/BoardsInfo/InfoProvider.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/Preparation/BoardsInfo/InfoProvider.php)

Какая логика сейчас в legacy:

- board export info comes from dedicated provider and is attached during hotel preparation

Что сделать:

1. Реализовать lookup-контракт.
2. Реализовать структуру данных `MappedBoard`.
3. Зафиксировать поведение при отсутствии mapping.

### Задача 2.5. Реализовать Export Policy Прочитать Model Boundary

Тип:

- backend

Зависит от:

- 0.6, 0.4

Приоритет:

- P1

Оценка:

- L

Блокируется:

- 0.6
- 0.4

Блокирует:

- 6.5
- 9.3

Какие legacy-файлы изучить:

- [modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Db/SeasonsHotelOtds.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Db/SeasonsHotelOtds.php)
- [modules/otds/src/Hotels/Preparation/HotelExportConfig/SeasonalRestrictions/RecordsFetcher.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/Preparation/HotelExportConfig/SeasonalRestrictions/RecordsFetcher.php)
- [modules/otds/src/Hotels/Preparation/HotelExportConfig/DayRestrictions/DefinitionsFetcher.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/Preparation/HotelExportConfig/DayRestrictions/DefinitionsFetcher.php)

Какая логика сейчас в legacy:

- OTDS export uses hotel-level policy records keyed by external code and additional dimensions
- policy lookup happens after hotel candidate is already selected and has external code

Что сделать:

1. Реализовать контракт запроса export policy.
2. Зафиксировать приоритет policy.
3. Зафиксировать как комбинируются несколько policy records.

### Задача 2.6. Принять решение по `RoomTypeFilter` Fate

Тип:

- backend

Зависит от:

- 0.5, 0.7

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 0.5
- 0.7

Блокирует:

- 4.10
- 9.6

Какие legacy-файлы изучить:

- [modules/xadmin/application/modules/export/forms/Roomtypefilter.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/export/forms/Roomtypefilter.php)
- [lib/classlib/Model/Export/RoomTypeFilter.php](/home/d.shein/Projects/xres_git/lib/classlib/Model/Export/RoomTypeFilter.php)
- [lib/classlib/RoomTypeFilter/Mapper.php](/home/d.shein/Projects/xres_git/lib/classlib/RoomTypeFilter/Mapper.php)
- [lib/classlib/RoomTypeFilter.php](/home/d.shein/Projects/xres_git/lib/classlib/RoomTypeFilter.php)

Какая логика сейчас в legacy:

- room type filter is a business policy collection by room type prefix, external code, operator and pax ranges
- this is not a computed RPAC table; it is a standalone policy surface

Что сделать:

1. Определить нужен ли этот механизм в greenfield.
2. Если нужен, определить новый policy-контракт.
3. Если не нужен, переложить поведение в occupancy override контракт.

---

## Этап 3. Реализация Input Layer

### Задача 3.1. Реализовать Descriptive SOAP Auth Builder

Тип:

- backend

Зависит от:

- 0.1

Приоритет:

- P1

Оценка:

- S

Блокируется:

- 0.1

Блокирует:

- 3.2
- 3.3

Какие legacy-файлы изучить:

- [modules/xhotels/classes/Provider/Synxis/Client/Common/Credential.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Common/Credential.php)
- [modules/xhotels/classes/Provider/Synxis/Client/Common/HTNGHeader.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Common/HTNGHeader.php)
- [modules/xhotels/classes/Provider/Synxis/Client/Common/From.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Common/From.php)

Какая логика сейчас в legacy:

- auth and headers are infrastructure pieces for descriptive endpoint
- they should not leak into orchestration code

Что сделать:

1. Выделить сборку заголовков.
2. Выделить представление credential.
3. Зафиксировать входные config-параметры.

### Задача 3.2. Реализовать Descriptive Request Builder

Тип:

- backend

Зависит от:

- 3.1

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 3.1

Блокирует:

- 3.3

Какие legacy-файлы изучить:

- [modules/xhotels/classes/Provider/Synxis/Client/Requests/HotelDescriptiveInfoRQ.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/HotelDescriptiveInfoRQ.php)
- [modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/HotelDescriptiveInfo.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/HotelDescriptiveInfo.php)
- [modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/HotelInfo.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/HotelInfo.php)
- [modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/FacilityInfo.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/FacilityInfo.php)
- [modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/Policies.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/Policies.php)

Какая логика сейчас в legacy:

- request sections explicitly determine which descriptive blocks are fetched
- request shape is a domain-relevant choice, not only transport syntax

Что сделать:

1. Зафиксировать минимально необходимые descriptive sections.
2. Отделить форму request от client execution.
3. Выделить один builder-контракт.

### Задача 3.3. Реализовать Descriptive Client

Тип:

- backend

Зависит от:

- 3.1, 3.2

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 3.1
- 3.2

Блокирует:

- 3.7
- 3.8

Какие legacy-файлы изучить:

- [modules/xhotels/classes/Provider/Synxis/Client/SynxisClient.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/SynxisClient.php)

Какая логика сейчас в legacy:

- client initializes SOAP, invokes request and returns last response payload
- faults are converted to provider exception

Что сделать:

1. Реализовать raw-XML transport method.
2. Нормализовать faults.
3. Сохранить no bundle/file concerns inside client.

### Задача 3.4. Реализовать APS Auth Builder

Тип:

- backend

Зависит от:

- 0.1

Приоритет:

- P1

Оценка:

- S

Блокируется:

- 0.1

Блокирует:

- 3.5
- 3.6

Какие legacy-файлы изучить:

- [modules/xhotels/classes/Provider/Synxis/APSClient/Requests/Headers/Header.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/Requests/Headers/Header.php)
- [modules/xhotels/classes/Provider/Synxis/APSClient/Requests/Headers/Security.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/Requests/Headers/Security.php)
- [modules/xhotels/classes/Provider/Synxis/APSClient/Requests/Headers/UsernameToken.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/Requests/Headers/UsernameToken.php)

Какая логика сейчас в legacy:

- WS-Security assembly is transport infrastructure and should not leak outward

Что сделать:

1. Выделить WS-Security header builder.
2. Зафиксировать auth config fields.

### Задача 3.5. Реализовать APS Request Builders

Тип:

- backend

Зависит от:

- 3.4

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 3.4

Блокирует:

- 3.6

Какие legacy-файлы изучить:

- [modules/xhotels/classes/Provider/Synxis/APSClient/Requests/GetRatesRequest.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/Requests/GetRatesRequest.php)
- [modules/xhotels/classes/Provider/Synxis/APSClient/Requests/GetInventoriesRequest.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/Requests/GetInventoriesRequest.php)
- [modules/xhotels/classes/Provider/Synxis/APSClient/Requests/GetAvailabilitiesRequest.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/Requests/GetAvailabilitiesRequest.php)
- [modules/xhotels/classes/Provider/Synxis/APSClient/Requests/Struct/PayloadRequest.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/Requests/Struct/PayloadRequest.php)

Какая логика сейчас в legacy:

- request wrappers are thin but still define distinct transport operations
- payload centers around hotel code and shared envelope structure

Что сделать:

1. Сохранить three explicit operations.
2. Share payload builder pieces safely.
3. Зафиксировать request контракты.

### Задача 3.6. Реализовать APS Client

Тип:

- backend

Зависит от:

- 3.4, 3.5

Приоритет:

- P1

Оценка:

- S

Блокируется:

- 3.4
- 3.5

Блокирует:

- 3.7
- 3.8

Какие legacy-файлы изучить:

- [modules/xhotels/classes/Provider/Synxis/APSClient/APSClient.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/APSClient.php)
- [modules/xhotels/classes/Provider/Synxis/APSClient/APSClientFactory.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/APSClientFactory.php)

Какая логика сейчас в legacy:

- client validates config and exposes `getRates`, `getInventory`, `getAvailabilities`
- raw response is read from SOAP client state

Что сделать:

1. Выделить raw response methods.
2. Нормализовать errors.
3. Отделить config factory from runtime orchestration.

### Задача 3.7. Реализовать `FetchHotelBundle` Use Case

Тип:

- backend

Зависит от:

- 3.3, 3.6, 1.1

Приоритет:

- P1

Оценка:

- L

Блокируется:

- 3.3
- 3.6
- 1.1

Блокирует:

- 3.9

Какие legacy-файлы изучить:

- [modules/xhotels/classes/Provider/Synxis/Command/Prices/DownloadPrices.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Command/Prices/DownloadPrices.php)

Какая логика сейчас в legacy:

- one orchestration command coordinates both transports and bundle delivery per hotel

Что сделать:

1. Создать explicit use case.
2. Подключить both transport clients.
3. Построить bundle object.
4. Сохранить bundle.
5. Запустить validation.

### Задача 3.8. Реализовать Bundle Retry Policy

Тип:

- backend

Зависит от:

- 0.7, 3.3, 3.6

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 0.7
- 3.3
- 3.6

Блокирует:

- нет

Какие legacy-файлы изучить:

- [modules/xhotels/classes/Framework/Application/Command/Prices/AbstractDownloadDeliveryCmd.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Framework/Application/Command/Prices/AbstractDownloadDeliveryCmd.php)

Какая логика сейчас в legacy:

- retry logic lives near file delivery, not near formal transport policy

Что сделать:

1. Выделить retry decisions.
2. Зафиксировать retryable error list.
3. Зафиксировать max attempts.
4. Зафиксировать per-file vs per-hotel behaviour.

### Задача 3.9. Реализовать Bundle Validation Service

Тип:

- backend

Зависит от:

- 0.1, 3.7, 0.7

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 0.1
- 3.7
- 0.7

Блокирует:

- 4.1
- 8.1
- 10.2
- 10.4

Что сделать:

1. Validate file presence.
2. Validate non-empty payload.
3. Validate XML structure.
4. Validate hotel consistency.
5. Сохранить validation result.

---

## Этап 4. Реализация Canonical Layer

### Задача 4.1. Реализовать Bundle Reader

Тип:

- backend

Зависит от:

- 1.1, 3.9

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 1.1
- 3.9

Блокирует:

- 4.2

Что сделать:

1. Прочитать 4-file bundle from persistence.
2. Возвращать raw payloads to parsing layer.
3. Сохранить storage concerns isolated.

### Задача 4.2. Реализовать Namespace Registry

Тип:

- backend

Зависит от:

- 4.1

Приоритет:

- P1

Оценка:

- S

Блокируется:

- 4.1

Блокирует:

- 4.3

Зачем нужна задача:

- legacy parsing is namespace-sensitive and today hidden inside factory logic

Что сделать:

1. Register required namespaces in one place.
2. Make parser depend on registry, not hardcoded local setup.

### Задача 4.3. Реализовать Parsed Document Types

Тип:

- backend

Зависит от:

- 4.2

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 4.2

Блокирует:

- 4.4
- 4.5
- 4.7
- 4.8
- 4.9
- 4.10

Что сделать:

1. Определить parsed wrapper for Rates.
2. Определить parsed wrapper for Inventory.
3. Определить parsed wrapper for Availabilities.
4. Определить parsed wrapper for Descriptive.

### Задача 4.4. Реализовать RatePlan Extraction

Тип:

- backend

Зависит от:

- 0.2, 4.3

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 0.2
- 4.3

Блокирует:

- 4.6
- 4.11

Что сделать:

1. Прочитать raw rate plan codes.
2. Прикрепить room references.
3. Прикрепить resolved board code via контракт mapping.
4. Сохранить currency references.

### Задача 4.5. Реализовать Room Extraction

Тип:

- backend

Зависит от:

- 0.2, 4.3

Приоритет:

- P1

Оценка:

- S

Блокируется:

- 0.2
- 4.3

Блокирует:

- 4.11

Что сделать:

1. Выделить provider room codes.
2. Сохранить raw source value.
3. Prepare canonical room candidates.
4. Link rooms to rate plans.

### Задача 4.6. Реализовать Board Resolution

Тип:

- backend

Зависит от:

- 2.2, 4.4

Приоритет:

- P1

Оценка:

- S

Блокируется:

- 2.2
- 4.4

Блокирует:

- 4.11

Что сделать:

1. Разрешить board from `rate_code -> meal_plan` mapping.
2. Обработать missing контракт mapping.
3. Сформировать canonical board collection.

### Задача 4.7. Реализовать Currency Resolution

Тип:

- backend

Зависит от:

- 4.3

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 4.3

Блокирует:

- 4.11

Что сделать:

1. Выделить currency.
2. Определить multi-currency conflicts.
3. Сформировать machine-readable reject if inconsistent.

### Задача 4.8. Реализовать Descriptive Room Extraction

Тип:

- backend

Зависит от:

- 4.3

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 4.3

Блокирует:

- 4.11
- 5.3

Что сделать:

1. Выделить descriptive room keys.
2. Нормализовать them for comparison.
3. Сформировать whitelist list.

### Задача 4.9. Реализовать Child Policy Resolver

Тип:

- backend

Зависит от:

- 4.3

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 4.3

Блокирует:

- 4.11
- 5.9

Что сделать:

1. Разрешить min adult age.
2. Разрешить child bounds.
3. Записать resolution source.
4. Emit warning/reject outcome.

### Задача 4.10. Реализовать Occupancy Constraint Provider

Тип:

- backend

Зависит от:

- 2.6, 4.3

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 2.6
- 4.3

Блокирует:

- 4.11
- 5.5

Что сделать:

1. Прочитать occupancy overrides from policy source.
2. Применить blanks/defaults.
3. Сформировать final occupancy ограничения for build.

### Задача 4.11. Собрать `HotelDataFactory`

Тип:

- backend

Зависит от:

- 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 4.10

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 4.4
- 4.5
- 4.6
- 4.7
- 4.8
- 4.9
- 4.10

Блокирует:

- 5.1
- 10.4

Что сделать:

1. Orchestrate subextractors.
2. Построить final `HotelData`.
3. Validate инварианты before return.

---

## Этап 5. RPAC Построить Implementation

### Задача 5.1. Реализовать Построить Eligibility Policy

Тип:

- backend

Зависит от:

- 0.3, 4.11, 0.7

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 0.3
- 4.11
- 0.7

Блокирует:

- 5.2

Что сделать:

1. Определить if hotel is buildable before heavy processing.
2. Определить if rate plan is buildable.
3. Distinguish warning from reject.

### Задача 5.2. Реализовать Offer Builder

Тип:

- backend

Зависит от:

- 5.1

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 5.1

Блокирует:

- 5.3
- 5.4
- 5.10

Что сделать:

1. Итерировать rate plans deterministically.
2. Создать one offer per resolved board.
3. Прикрепить идентификатор offer.

### Задача 5.3. Реализовать Descriptive Whitelist Filtering

Тип:

- backend

Зависит от:

- 4.8, 5.2, 0.7

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 4.8
- 5.2
- 0.7

Блокирует:

- 5.10

Что сделать:

1. Сравнить build rooms vs descriptive rooms.
2. Remove inconsistent rooms.
3. Записать warnings/rejects.

### Задача 5.4. Реализовать Intersection Builder

Тип:

- backend

Зависит от:

- 5.2, 0.5

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 5.2
- 0.5

Блокирует:

- 5.5
- 5.6
- 5.9

Что сделать:

1. Скомбинировать room + board.
2. Применить канонический идентификатор room.
3. Прикрепить occupancies.
4. Emit traceable base intersection.

### Задача 5.5. Реализовать Occupancy Builder

Тип:

- backend

Зависит от:

- 4.10, 5.4

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 4.10
- 5.4

Блокирует:

- 5.10

Что сделать:

1. Expand allowed occupancies.
2. Применить occupancy overrides.
3. Drop invalid intersections.

### Задача 5.6. Реализовать Inventory Reducer

Тип:

- backend

Зависит от:

- 5.4

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 5.4

Блокирует:

- 5.7
- 5.10

Что сделать:

1. Consume inventory timeline.
2. Determine exportable date ranges.
3. Возвращать structured inventory outcome.

### Задача 5.7. Реализовать Availability Reducer

Тип:

- backend

Зависит от:

- 5.6

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 5.6

Блокирует:

- 5.8
- 5.10

Что сделать:

1. Применить open/close.
2. Применить CTA/CTD.
3. Применить LOS.
4. Применить booking offsets.
5. Возвращать structured availability outcome.

### Задача 5.8. Реализовать Booking Offset Policy

Тип:

- backend

Зависит от:

- 5.7

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 5.7

Блокирует:

- 5.10

Какие legacy-файлы изучить:

- [modules/xhotels/classes/Provider/Synxis/Rpac/BookingOffsetsHelper.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/BookingOffsetsHelper.php)

Какая логика сейчас в legacy:

- booking restrictions are a discrete policy layer and should stay separate from generic availability mechanics

Что сделать:

1. Зафиксировать booking-offset semantics.
2. Зафиксировать precedence in reduction order.
3. Сформировать structured filter output.

### Задача 5.9. Реализовать Price Builder

Тип:

- backend

Зависит от:

- 5.4, 4.9

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 5.4
- 4.9

Блокирует:

- 5.10

Что сделать:

1. Прочитать price rows.
2. Разрешить pax/age qualifiers.
3. Построить `RpacPrice` rows.
4. Обработать conflicting rows by weight.

### Задача 5.10. Реализовать Построить Warning/Reject Aggregator

Тип:

- backend

Зависит от:

- 0.7, 5.2, 5.3, 5.5, 5.6, 5.7, 5.8, 5.9

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 0.7
- 5.2
- 5.3
- 5.5
- 5.6
- 5.7
- 5.8
- 5.9

Блокирует:

- 5.11

Что сделать:

1. Собрать machine-readable warnings.
2. Собрать machine-readable rejects.
3. Aggregate by scope.

### Задача 5.11. Реализовать RPAC Compiler

Тип:

- backend

Зависит от:

- 5.10

Приоритет:

- P1

Оценка:

- L

Блокируется:

- 5.10

Блокирует:

- 6.3
- 6.4
- 7.6
- 8.2
- 10.1
- 10.2
- 10.3
- 10.4

Что сделать:

1. Compile offers.
2. Compile intersections.
3. Compile stats.
4. Сохранить or return final build object.

---

## Этап 6. OTDS Mapping И Preparation

### Задача 6.1. Реализовать Hotel Selection Adapter

Тип:

- backend

Зависит от:

- 2.1, 0.6

Приоритет:

- P1

Оценка:

- S

Блокируется:

- 2.1
- 0.6

Блокирует:

- 6.2
- 6.5
- 7.7

Что сделать:

1. Select exportable hotels from hotel matching.
2. Сохранить `external_code` ordering.
3. Сохранить product type and export status gating.

### Задача 6.2. Реализовать Hotel Master Data Attachment

Тип:

- backend

Зависит от:

- 6.1

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 6.1

Блокирует:

- 6.6

Зачем нужна задача:

- export candidate needs region, destination and other hotel-level properties separate from RPAC combinatorics

Что сделать:

1. Прикрепить hotel master data.
2. Зафиксировать required export fields.
3. Reject missing mandatory master data.

### Задача 6.3. Реализовать Room Mapping Attachment

Тип:

- backend

Зависит от:

- 2.3, 5.11

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 2.3
- 5.11

Блокирует:

- 6.6
- 7.5

Что сделать:

1. Сопоставить all room идентификаторы.
2. Remove unmapped combinations.
3. Записать reject reasons.

### Задача 6.4. Реализовать Board Mapping Attachment

Тип:

- backend

Зависит от:

- 2.4, 5.11

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 2.4
- 5.11

Блокирует:

- 6.6
- 7.4

Что сделать:

1. Сопоставить all board идентификаторы.
2. Remove unmapped combinations.
3. Записать reject reasons.

### Задача 6.5. Реализовать Export Policy Application

Тип:

- backend

Зависит от:

- 2.5, 6.1

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 2.5
- 6.1

Блокирует:

- 6.6

Что сделать:

1. Применить season restrictions.
2. Применить day restrictions.
3. Применить duration and operator restrictions.
4. Сохранить explanation for removals.

### Задача 6.6. Реализовать `ExportReadyHotel` Builder

Тип:

- backend

Зависит от:

- 6.2, 6.3, 6.4, 6.5

Приоритет:

- P1

Оценка:

- L

Блокируется:

- 6.2
- 6.3
- 6.4
- 6.5

Блокирует:

- 7.1
- 7.2
- 10.1
- 10.4

Что сделать:

1. Скомбинировать RPAC result + master data + mappings + policies.
2. Определить hotel-level reject if empty.
3. Возвращать stable writer input object.

---

## Этап 7. OTDS Export Implementation

### Задача 7.1. Реализовать Envelope Writer

Тип:

- backend

Зависит от:

- 0.4, 6.6

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 0.4
- 6.6

Блокирует:

- 7.2
- 7.7
- 7.8

Что сделать:

1. Open document.
2. Write root attributes.
3. Write `Brands` and `Accommodations` scaffolding.
4. Close document safely.

### Задача 7.2. Реализовать Accommodation Writer

Тип:

- backend

Зависит от:

- 7.1, 6.6

Приоритет:

- P1

Оценка:

- S

Блокируется:

- 7.1
- 6.6

Блокирует:

- 7.3
- 7.8

Что сделать:

1. Write accommodation node.
2. Write hotel-level metadata.
3. Сохранить grouping semantics.

### Задача 7.3. Реализовать SellingAccom Writer

Тип:

- backend

Зависит от:

- 7.2

Приоритет:

- P1

Оценка:

- S

Блокируется:

- 7.2

Блокирует:

- 7.4
- 7.5
- 7.6
- 7.8

Что сделать:

1. Write hotel selling surface.
2. Прикрепить boards, units and selling units in correct structure.

### Задача 7.4. Реализовать Board Writer

Тип:

- backend

Зависит от:

- 6.4, 7.3

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 6.4
- 7.3

Блокирует:

- 7.8

Что сделать:

1. Serialize mapped boards.
2. Сохранить writer free from lookup logic.

### Задача 7.5. Реализовать Unit Writer

Тип:

- backend

Зависит от:

- 6.3, 7.3

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 6.3
- 7.3

Блокирует:

- 7.8

Что сделать:

1. Serialize mapped rooms.
2. Сохранить canonical/export identity separation.

### Задача 7.6. Реализовать SellingUnit Writer

Тип:

- backend

Зависит от:

- 5.11, 7.3

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 5.11
- 7.3

Блокирует:

- 7.8

Что сделать:

1. Serialize prices.
2. Serialize availability.
3. Serialize restrictions/filters.
4. Snapshot-test node output.

### Задача 7.7. Реализовать Grouping By External Code

Тип:

- backend

Зависит от:

- 6.1, 7.1

Приоритет:

- P1

Оценка:

- M

Блокируется:

- 6.1
- 7.1

Блокирует:

- 7.8

Какие legacy-файлы изучить:

- [modules/otds/src/Payload/HotelFileWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/HotelFileWriter.php)

Какая логика сейчас в legacy:

- writer keeps streaming state and groups hotels with same external code into one `Accommodation`

Что сделать:

1. Сохранить ordered grouping.
2. Сохранить streaming-friendly memory behaviour.

### Задача 7.8. Реализовать Archive Packaging

Тип:

- backend

Зависит от:

- 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 1.6

Приоритет:

- P1

Оценка:

- L

Блокируется:

- 7.1
- 7.2
- 7.3
- 7.4
- 7.5
- 7.6
- 7.7
- 1.6

Блокирует:

- 8.4
- 10.1
- 10.2
- 10.3
- 10.4

Что сделать:

1. Write xml file.
2. Write base files if needed.
3. Package archive.
4. Сохранить artifact metadata.

---

## Этап 8. Read-Only Operational Surfaces

### Задача 8.1. Реализовать `Synxis Bundle Browser`

Тип:

- xadmin

Зависит от:

- 1.1, 3.9

Приоритет:

- P2

Оценка:

- M

Блокируется:

- 1.1
- 3.9

Блокирует:

- нет

Что сделать:

1. Show bundle list.
2. Show validation status.
3. Show xml artifact links.
4. Добавить revalidate/rebuild actions.

### Задача 8.2. Реализовать `RPAC Построить Browser`

Тип:

- xadmin

Зависит от:

- 1.5, 5.11, 1.7

Приоритет:

- P2

Оценка:

- M

Блокируется:

- 1.5
- 5.11
- 1.7

Блокирует:

- нет

Что сделать:

1. Show RPAC versions.
2. Show status and stats.
3. Show warnings/reject counts.
4. Добавить rebuild action.

### Задача 8.3. Реализовать `Warnings / Rejects Viewer`

Тип:

- xadmin

Зависит от:

- 1.7, 0.7

Приоритет:

- P2

Оценка:

- S

Блокируется:

- 1.7
- 0.7

Блокирует:

- нет

Что сделать:

1. Show machine-readable коды.
2. Show entity scope.
3. Show payload context.

### Задача 8.4. Реализовать `OTDS Export Browser`

Тип:

- xadmin

Зависит от:

- 1.6, 7.8

Приоритет:

- P2

Оценка:

- S

Блокируется:

- 1.6
- 7.8

Блокирует:

- нет

Что сделать:

1. Show export runs.
2. Show artifact paths.
3. Добавить download actions.
4. Добавить re-export action.

---

## Этап 9. Редактируемые Admin-Surface

### Задача 9.1. Сохранить surface `Hotel Matching / External Code`

Тип:

- xadmin

Зависит от:

- 2.1, 0.6, 1.8

Приоритет:

- P2

Оценка:

- S

Блокируется:

- 2.1
- 0.6
- 1.8

Блокирует:

- нет

Почему это делается после БД:

- только после фиксации таблиц и семантики отбора можно безопасно сохранять этот UI или менять его границы

Что сделать:

1. Зафиксировать ownership для source of truth.
2. Сохранить редактируемые поля, влияющие на export selection.
3. Не допустить появления второго конфликтующего источника истины.

### Задача 9.2. Сохранить surface `SynxisContractDetails`

Тип:

- xadmin

Зависит от:

- 1.2, 2.2

Приоритет:

- P2

Оценка:

- S

Блокируется:

- 1.2
- 2.2

Блокирует:

- нет

Что сделать:

1. Сохранить текущий business meaning формы.
2. Переосмыслить `meal_plan` как идентификатор board в greenfield-домене.
3. Сохранить правила уникальности и scope по environment.

### Задача 9.3. Сохранить surface `ExportSeasonsHotelOtds`

Тип:

- xadmin

Зависит от:

- 2.5, 0.6

Приоритет:

- P2

Оценка:

- S

Блокируется:

- 2.5
- 0.6

Блокирует:

- нет

Что сделать:

1. Сохранить текущую роль hotel-level export policy.
2. Сохранить validation logic.
3. Явно зафиксировать, что `external_hotel_code` это lookup key, а не identity source.

### Задача 9.4. Добавить `Provider Room Mapping` CRUD

Тип:

- xadmin

Зависит от:

- 1.3, 2.3

Приоритет:

- P2

Оценка:

- M

Блокируется:

- 1.3
- 2.3

Блокирует:

- нет

Что сделать:

1. Добавить CRUD-экран.
2. Добавить валидаторы уникальности.
3. Добавить audit history, если это требуется платформой.

### Задача 9.5. Добавить `Provider Board Mapping` CRUD

Тип:

- xadmin

Зависит от:

- 1.4, 2.4

Приоритет:

- P2

Оценка:

- M

Блокируется:

- 1.4
- 2.4

Блокирует:

- нет

Что сделать:

1. Добавить CRUD-экран.
2. Добавить валидаторы уникальности.
3. Добавить audit history, если это требуется платформой.

### Задача 9.6. Принять решение по итоговой судьбе UI `RoomTypeFilter`

Тип:

- xadmin

Зависит от:

- 2.6

Приоритет:

- P2

Оценка:

- S

Блокируется:

- 2.6

Блокирует:

- нет

Что сделать:

1. Сохранить legacy-форму, если policy остаётся.
2. Либо вывести её из эксплуатации с явной миграцией, если policy поглощается в другом месте.

---

## Этап 10. Observability, Replay И Rollout

### Задача 10.1. Добавить структурированный tracing

Тип:

- backend

Зависит от:

- 5.11, 6.6, 7.8

Приоритет:

- P2

Оценка:

- M

Блокируется:

- 5.11
- 6.6
- 7.8

Блокирует:

- нет

Что сделать:

1. Трассировать по `hotel_code`.
2. Трассировать по `bundle_id`.
3. Трассировать по `rpac_version`.
4. Трассировать по `external_code` во время экспорта.

### Задача 10.2. Добавить метрики

Тип:

- backend

Зависит от:

- 3.9, 5.11, 7.8

Приоритет:

- P2

Оценка:

- M

Блокируется:

- 3.9
- 5.11
- 7.8

Блокирует:

- нет

Что сделать:

1. Метрики input-слоя.
2. Метрики валидации.
3. Метрики сборки.
4. Метрики экспорта.
5. Счётчики error/reject.

### Задача 10.3. Добавить replay-команды

Тип:

- backend

Зависит от:

- 1.7, 5.11, 7.8

Приоритет:

- P2

Оценка:

- M

Блокируется:

- 1.7
- 5.11
- 7.8

Блокирует:

- нет

Что сделать:

1. Повторно провалидировать bundle.
2. Пересобрать RPAC из bundle.
3. Повторно экспортировать из версии RPAC.

### Задача 10.4. Добавить golden-path fixture

Тип:

- e2e

Зависит от:

- 2.1, 2.2, 3.9, 4.11, 5.11, 6.6, 7.8

Приоритет:

- P0 validation slice

Оценка:

- L

Блокируется:

- 2.1
- 2.2
- 3.9
- 4.11
- 5.11
- 6.6
- 7.8

Блокирует:

- 10.5

Что сделать:

1. Один стабильный отель.
2. Один полный валидный bundle.
3. Один snapshot `HotelData`.
4. Один snapshot `RpacBuildResult`.
5. Один snapshot `ExportReadyHotel`.
6. Один OTDS XML golden-файл.

### Задача 10.5. Добавить негативные fixture-наборы

Тип:

- e2e

Зависит от:

- 10.4, 0.7

Приоритет:

- P2

Оценка:

- M

Блокируется:

- 10.4
- 0.7

Блокирует:

- нет

Что сделать:

1. Отсутствующий файл.
2. Невалидный XML.
3. Несовпадение hotel code.
4. Неотмапленная room.
5. Неотмапленный board.
6. Несогласованная descriptive room.
7. Перекрывающиеся цены.

---

## Рекомендуемый Порядок Реализации

Если реализацию будет начинать другой агент, порядок должен быть таким:

1. Полностью закрыть Этап 0
2. Полностью закрыть Этап 1
3. Полностью закрыть Этап 2
4. Полностью закрыть Этап 3
5. Полностью закрыть Этап 4
6. Полностью закрыть Этап 5
7. Полностью закрыть Этап 6
8. Полностью закрыть Этап 7
9. Полностью закрыть Этап 8
10. Полностью закрыть Этап 9
11. Полностью закрыть Этап 10

## Минимальный Полезный Срез

Минимальный полезный срез для первой рабочей поставки:

1. источник `hotel_matching` с одним валидным `external_code`
2. один набор mapping в `SynxisContractDetails`
3. один полный валидный bundle из 4 файлов
4. один `HotelData`
5. один `RpacBuildResult`
6. один room mapping
7. один board mapping
8. один `ExportReadyHotel`
9. один OTDS XML-файл

## MVP-Пул Задач

Ниже перечислен не абстрактный минимальный срез, а конкретный пул задач, который нужен для первой рабочей версии пайплайна. Внутри каждого этапа задачи отсортированы по реальному порядку выполнения, а не просто по номеру:

- цель MVP: получить один валидный путь `Synxis bundle -> HotelData -> RPAC -> ExportReadyHotel -> OTDS XML archive`
- в MVP не входят admin-экраны, read-only браузеры, replay tooling, metrics и расширенные negative fixtures
- в MVP входят только те задачи, без которых нельзя собрать и прогнать один рабочий happy-path end-to-end

### 1. Контракты И Правила

- `0.1` Зафиксировать `SynxisHotelBundle`
- `0.2` Зафиксировать `HotelData`
- `0.5` Зафиксировать правила идентификаторов
- `0.6` Зафиксировать External Code Source Of Truth
- `0.7` Зафиксировать taxonomy ошибок и reject-сценариев
- `0.8` Зафиксировать state machine по ключевым сущностям
- `0.3` Зафиксировать `RpacBuildResult`
- `0.4` Зафиксировать `ExportReadyHotel`

### 2. База И Persistence

- `1.1` Спроектировать таблицу `synxis_hotel_bundle`
- `1.2` Спроектировать таблицу `provider_rateplan_board_mapping`
- `1.3` Спроектировать таблицу `provider_room_mapping`
- `1.4` Спроектировать таблицу `provider_board_mapping`
- `1.5` Спроектировать таблицы хранения RPAC
- `1.8` Определить порядок миграций

### 3. Legacy-Адаптеры

- `2.1` Реализовать read-model boundary для `HotelMatching`
- `2.2` Реализовать read-model boundary для `ContractDetails`
- `2.3` Реализовать Room Mapping Прочитать Model Boundary
- `2.4` Реализовать Board Mapping Прочитать Model Boundary
- `2.5` Реализовать Export Policy Прочитать Model Boundary

### 4. Input Layer

- `3.1` Реализовать Descriptive SOAP Auth Builder
- `3.2` Реализовать Descriptive Request Builder
- `3.3` Реализовать Descriptive Client
- `3.4` Реализовать APS Auth Builder
- `3.5` Реализовать APS Request Builders
- `3.6` Реализовать APS Client
- `3.7` Реализовать `FetchHotelBundle` Use Case
- `3.9` Реализовать Bundle Validation Service

### 5. Canonical Layer

- `4.2` Реализовать Namespace Registry
- `4.3` Реализовать Parsed Document Types
- `4.1` Реализовать Bundle Reader
- `4.4` Реализовать RatePlan Extraction
- `4.5` Реализовать Room Extraction
- `4.7` Реализовать Currency Resolution
- `4.8` Реализовать Descriptive Room Extraction
- `4.9` Реализовать Child Policy Resolver
- `4.6` Реализовать Board Resolution
- `4.10` Реализовать Occupancy Constraint Provider
- `4.11` Собрать `HotelDataFactory`

### 6. RPAC Build

- `5.1` Реализовать Построить Eligibility Policy
- `5.2` Реализовать Offer Builder
- `5.3` Реализовать Descriptive Whitelist Filtering
- `5.4` Реализовать Intersection Builder
- `5.5` Реализовать Occupancy Builder
- `5.6` Реализовать Inventory Reducer
- `5.7` Реализовать Availability Reducer
- `5.8` Реализовать Booking Offset Policy
- `5.9` Реализовать Price Builder
- `5.10` Реализовать Построить Warning/Reject Aggregator
- `5.11` Реализовать RPAC Compiler

### 7. Export-Ready Layer

- `6.1` Реализовать Hotel Selection Adapter
- `6.2` Реализовать Hotel Master Data Attachment
- `6.3` Реализовать Room Mapping Attachment
- `6.4` Реализовать Board Mapping Attachment
- `6.5` Реализовать Export Policy Application
- `6.6` Реализовать `ExportReadyHotel` Builder

### 8. OTDS Writer

- `7.1` Реализовать Envelope Writer
- `7.7` Реализовать Grouping By External Code
- `7.2` Реализовать Accommodation Writer
- `7.3` Реализовать SellingAccom Writer
- `7.4` Реализовать Board Writer
- `7.5` Реализовать Unit Writer
- `7.6` Реализовать SellingUnit Writer
- `7.8` Реализовать Archive Packaging

### 9. MVP-Валидация

- `10.4` Добавить golden-path fixture

### Что Явно Не Входит В MVP-Пул

- `1.6` таблицы export run и artifacts
- `1.7` отдельное хранение warnings и rejects
- `2.6` решение по `RoomTypeFilter`
- `3.8` retry policy
- `8.1`-`8.4` все read-only operational surfaces
- `9.1`-`9.6` все editable admin surfaces
- `10.1` tracing
- `10.2` metrics
- `10.3` replay-команды
- `10.5` негативные fixture-наборы

### Практический Порядок Внутри MVP-Пула

1. Полностью закрыть этап контрактов и правил
2. Зафиксировать таблицы и только потом порядок миграций
3. Собрать все legacy-read adapters до начала orchestration
4. Поднять оба transport-клиента и use case получения bundle
5. После этого делать canonical parsing и сборку `HotelData`
6. Затем собирать RPAC целиком
7. Потом строить `ExportReadyHotel`
8. После этого писать OTDS XML writer и archive packaging
9. Закрыть `10.4` как финальную golden-path проверку MVP

## MVP Sprint 1

Рабочая декомпозиция этого спринта и синхронизированные planning-документы вынесены в:

- [`docs/Sprint1/INDEX_SPRINT1.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/INDEX_SPRINT1.md:1)

Важно:

- backlog ниже исторически использует часть Synxis-centric naming
- в planning-пакете `Sprint1` core ingestion layer уже нормализован как generic механизм
- `Synxis` трактуется как reference provider profile поверх этого generic core

Цель спринта: зафиксировать модель, таблицы и входной контур, чтобы система умела получить и провалидировать один bundle.

Задачи:

- `0.1`, `0.2`, `0.5`, `0.6`, `0.7`, `0.8`, `0.3`, `0.4`
- `1.1`, `1.2`, `1.3`, `1.4`, `1.5`, `1.8`
- `2.1`, `2.2`, `2.3`, `2.4`, `2.5`
- `3.1`, `3.2`, `3.3`, `3.4`, `3.5`, `3.6`, `3.7`, `3.9`

Результат спринта:

- есть зафиксированные контракты
- есть DDL и порядок миграций
- есть адаптеры к обязательным legacy-источникам
- система умеет получить валидный `SynxisHotelBundle`

## MVP Sprint 2

Цель спринта: превратить bundle в канонический `HotelData` и затем в полный `RpacBuildResult`.

Задачи:

- `4.2`, `4.3`, `4.1`, `4.4`, `4.5`, `4.7`, `4.8`, `4.9`, `4.6`, `4.10`, `4.11`
- `5.1`, `5.2`, `5.3`, `5.4`, `5.5`, `5.6`, `5.7`, `5.8`, `5.9`, `5.10`, `5.11`

Результат спринта:

- есть deterministic parsing всех 4 XML
- есть стабильный `HotelData`
- есть полный `RpacBuildResult` для одного отеля

## MVP Sprint 3

Цель спринта: собрать export-ready модель, записать OTDS XML и закрыть golden-path fixture.

Задачи:

- `6.1`, `6.2`, `6.3`, `6.4`, `6.5`, `6.6`
- `7.1`, `7.7`, `7.2`, `7.3`, `7.4`, `7.5`, `7.6`, `7.8`
- `10.4`

Результат спринта:

- есть `ExportReadyHotel`
- есть OTDS XML archive для одного валидного сценария
- есть golden-path fixture, который фиксирует MVP end-to-end

## Итоговое Замечание

Этот проект не должен начинаться с форм.

Он должен начинаться со следующего:

- контракты
- база данных
- адаптеры
- пайплайн
- export
- и только потом интерфейсы

Это единственный порядок, при котором система остаётся детерминированной и объяснимой.
