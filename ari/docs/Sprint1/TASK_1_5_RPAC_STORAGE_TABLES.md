# Sprint 1 - Task 1.5

## Спроектировать таблицы хранения RPAC

## Таблицы

В scope задачи входят:

- `rpac_hotels`
- `rpac_offers`
- `rpac_intersections`
- `rpac_prices`
- `rpac_availabilities`
- `rpac_filters`

## Общий принцип

RPAC storage должен хранить:

- immutable build result
- provenance через `bundle_id`
- build version

Он не должен хранить editable business source-of-truth mappings.

## 1. `rpac_hotels`

### Колонки

| Колонка | Тип | Null |
|---|---|---|
| `id` | `uuid` | no |
| `provider` | `varchar(64)` | no |
| `hotel_code` | `varchar(128)` | no |
| `version` | `integer` | no |
| `status` | `varchar(32)` | no |
| `currency` | `varchar(16)` | no |
| `bundle_id` | `uuid` | no |
| `warnings_count` | `integer` | no |
| `rejects_count` | `integer` | no |
| `intersections_count` | `integer` | no |
| `inserted_at` | `timestamptz` | no |
| `updated_at` | `timestamptz` | no |

### Constraints

- `unique (provider, hotel_code, version)`
- `bundle_id -> provider_hotel_bundle.id`

## 2. `rpac_offers`

### Колонки

| Колонка | Тип | Null |
|---|---|---|
| `id` | `uuid` | no |
| `rpac_hotel_id` | `uuid` | no |
| `rate_plan_code` | `varchar(128)` | no |
| `board_code` | `varchar(128)` | no |
| `offer_identity` | `varchar(255)` | no |
| `inserted_at` | `timestamptz` | no |
| `updated_at` | `timestamptz` | no |

### Constraints

- `unique (rpac_hotel_id, rate_plan_code, board_code)`

## 3. `rpac_intersections`

### Колонки

| Колонка | Тип | Null |
|---|---|---|
| `id` | `uuid` | no |
| `rpac_offer_id` | `uuid` | no |
| `room_code_canonical` | `varchar(255)` | no |
| `board_code` | `varchar(128)` | no |
| `intersection_identity` | `varchar(255)` | no |
| `inserted_at` | `timestamptz` | no |
| `updated_at` | `timestamptz` | no |

### Constraints

- `unique (rpac_offer_id, room_code_canonical)`

## 4. `rpac_prices`

Минимально:

- `id`
- `intersection_id`
- `date_from`
- `date_to`
- `amount`
- `currency`
- `guest_count`
- `age_qualifying_code`
- `min_age`
- `max_age`
- `weight`

## 5. `rpac_availabilities`

Минимально:

- `id`
- `intersection_id`
- `date_from`
- `date_to`
- `availability_type`

## 6. `rpac_filters`

Минимально:

- `id`
- `intersection_id`
- `filter_type`
- `payload_json`

## Что хранить, а что пересчитывать

### Хранить

- build result snapshot
- identities
- provenance
- final prices/availabilities/filters
- aggregate counts

### Не хранить как editable source

- raw XML
- mapping source-of-truth
- temporary parser state

## Что это разблокирует

После `1.5` можно:

- финализировать migration order
- строить read-only RPAC surfaces
- готовить export-ready assembly
