# Sprint 1 - Task 1.2

## Спроектировать таблицу `provider_rateplan_board_mapping`

## Роль таблицы

Это source of truth для резолва:

- `rate_plan_code -> board_code`

Таблица не должна смешиваться с export board metadata. Её задача уже на canonical/build boundary дать стабилизированный `board_code`.

## Scope

Минимальный scope:

- `provider`
- `environment`
- `hotel_code`
- `rate_plan_code`

## Колонки

| Колонка | Тип | Null | Смысл |
|---|---|---|---|
| `id` | `uuid` | no | PK |
| `provider` | `varchar(64)` | no | provider namespace |
| `environment` | `varchar(32)` | no | env scope |
| `hotel_code` | `varchar(128)` | no | hotel scope |
| `rate_plan_code` | `varchar(128)` | no | provider rate plan |
| `board_code` | `varchar(128)` | no | canonical board identity |
| `active` | `boolean` | no | lifecycle flag |
| `comment` | `text` | yes | operational note |
| `inserted_at` | `timestamptz` | no | audit |
| `updated_at` | `timestamptz` | no | audit |

## Уникальность

Нужно:

- `unique (provider, environment, hotel_code, rate_plan_code)`

## Индексы

- `(provider, environment, hotel_code)`
- `(board_code)`
- `(active)`

## Synxis mapping from legacy

Legacy fields:

- `rate_code -> rate_plan_code`
- `meal_plan -> board_code`

## Ownership

Owner:

- business ops / mapping admin

Writer не должен менять эту таблицу.

