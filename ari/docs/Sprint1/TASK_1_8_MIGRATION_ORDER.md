# Sprint 1 - Task 1.8

## Порядок миграций

Этот документ фиксирует migration order в рамках:

- [`SYNXIS_RPAC_OTDS_GREENFIELD_SPEC.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/SYNXIS_RPAC_OTDS_GREENFIELD_SPEC.md:1)
- [`SYNXIS_RPAC_OTDS_TASKS.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/SYNXIS_RPAC_OTDS_TASKS.md:802)

И продолжает:

- [TASK_1_1_PROVIDER_HOTEL_BUNDLE_TABLE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_1_1_PROVIDER_HOTEL_BUNDLE_TABLE.md:1)

## Важная коллизия в backlog

В `TASKS.md` задача `1.8` формально зависит от:

- `1.1`
- `1.2`
- `1.3`
- `1.4`
- `1.5`
- `1.6`
- `1.7`

Но ниже в MVP-пуле явно сказано, что:

- `1.6` не входит в MVP
- `1.7` не входит в MVP

Поэтому правильная интерпретация такая:

1. есть **полный migration order** для всей target architecture
2. есть **MVP migration order** для Sprint 1

Оба порядка нужно зафиксировать отдельно.

## Базовый принцип

Порядок миграций должен идти:

1. core bundle storage
2. mapping/source-of-truth tables
3. RPAC storage
4. operational/export tables
5. warning/reject storage

Нельзя делать наоборот, потому что:

- RPAC зависит от bundle
- export зависит от RPAC
- admin и read-only surfaces зависят от уже существующих source-of-truth таблиц

## Полный migration order

### Wave 1. Ingestion Core

1. `provider_hotel_bundle`
2. `provider_hotel_bundle_file`

Причина:

- это корневая входная сущность
- от неё зависят ingestion, validation, replay и downstream build provenance

### Wave 2. Provider Mapping / Source of Truth

3. `provider_rateplan_board_mapping`
4. `provider_room_mapping`
5. `provider_board_mapping`

Причина:

- это source of truth для board, room и export mapping
- canonical/build/export layers должны ссылаться на уже определённые mapping boundaries

### Wave 3. RPAC Core

6. `rpac_hotels`
7. `rpac_offers`
8. `rpac_intersections`
9. `rpac_prices`
10. `rpac_availabilities`
11. `rpac_filters`

Причина:

- `rpac_hotels` зависит от bundle
- offer/intersection children зависят от `rpac_hotels`
- prices/availabilities/filters зависят от intersections

### Wave 4. Export / Operations

12. `export_runs`
13. `export_artifacts`

Причина:

- export artifacts зависят от уже собранной RPAC version
- они не нужны для первого валидного bundle

### Wave 5. Warnings / Rejects

14. `build_events` или equivalent table для warnings/rejects

Причина:

- warning/reject storage зависит от определённой taxonomy
- её можно вводить после core schema

## MVP migration order для Sprint 1

Так как `1.6` и `1.7` явно вне MVP, для Sprint 1 правильный order такой:

### MVP Wave 1

1. `provider_hotel_bundle`
2. `provider_hotel_bundle_file`

### MVP Wave 2

3. `provider_rateplan_board_mapping`
4. `provider_room_mapping`
5. `provider_board_mapping`

### MVP Wave 3

6. `rpac_hotels`
7. `rpac_offers`
8. `rpac_intersections`
9. `rpac_prices`
10. `rpac_availabilities`
11. `rpac_filters`

### Deferred beyond MVP

12. `export_runs`
13. `export_artifacts`
14. `build_events` / warnings / rejects storage

## Зависимости между таблицами

### `provider_hotel_bundle_file`

Зависит от:

- `provider_hotel_bundle`

### `rpac_hotels`

Зависит от:

- `provider_hotel_bundle`

Потому что:

- `rpac_hotels.bundle_id` должен ссылаться на bundle provenance

### `rpac_offers`

Зависит от:

- `rpac_hotels`

### `rpac_intersections`

Зависит от:

- `rpac_offers`

### `rpac_prices`

Зависит от:

- `rpac_intersections`

### `rpac_availabilities`

Зависит от:

- `rpac_intersections`

### `rpac_filters`

Зависит от:

- `rpac_intersections`

### `export_runs` и `export_artifacts`

Зависят от:

- `rpac_hotels`

### `warnings/rejects`

Минимально зависят от:

- taxonomy
- scope model
- bundle/build versioning

## Рекомендуемая нумерация миграций

Пример логического порядка:

1. `create_provider_hotel_bundles`
2. `create_provider_hotel_bundle_files`
3. `create_provider_rateplan_board_mappings`
4. `create_provider_room_mappings`
5. `create_provider_board_mappings`
6. `create_rpac_hotels`
7. `create_rpac_offers`
8. `create_rpac_intersections`
9. `create_rpac_prices`
10. `create_rpac_availabilities`
11. `create_rpac_filters`
12. `create_export_runs`
13. `create_export_artifacts`
14. `create_build_events`

## Почему mapping-таблицы идут до RPAC

Даже если физически RPAC-таблицы можно создать раньше, логически лучше сначала создать mapping/source-of-truth слой, потому что:

- он нужен для canonical/build semantics
- он раньше stabilizes business ownership
- он соответствует database-first подходу из `TASKS.md`

## Что делать с legacy naming

Если в текущем репозитории временно используются Synxis-oriented имена, migration order всё равно надо фиксировать в generic форме.

Причина:

- backlog уже показал, что механизм должен быть универсальным
- provider-specific naming на уровне core schema быстро станет архитектурным долгом

## Acceptance criteria для 1.8

Задачу можно считать закрытой, если:

1. есть полный порядок миграций для target architecture
2. есть отдельный MVP-порядок для Sprint 1
3. bundle storage идёт раньше RPAC storage
4. RPAC storage идёт раньше export storage
5. отмечена коллизия между формальными зависимостями `1.8` и MVP-исключениями `1.6/1.7`

## Практический следующий шаг

После этого документа уже можно:

1. писать реальные Ecto migrations в нужной последовательности
2. проектировать Ecto schemas
3. начать persistence flow для `FetchHotelBundle`
