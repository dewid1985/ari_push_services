# Sprint 1 - Task 1.3

## Спроектировать таблицу `provider_room_mapping`

## Роль таблицы

Это source of truth для room export mapping.

Она отвечает за перевод:

- `provider_room_code_canonical`
- в export-ready room representation

## Scope

Минимальный scope:

- `provider`
- `hotel_code`
- `provider_room_code_canonical`

`environment` добавлять только если реально понадобится env-specific mapping.

## Колонки

| Колонка | Тип | Null | Смысл |
|---|---|---|---|
| `id` | `uuid` | no | PK |
| `provider` | `varchar(64)` | no | provider namespace |
| `hotel_code` | `varchar(128)` | no | hotel scope |
| `provider_room_code` | `varchar(128)` | no | raw provider room code |
| `provider_room_code_canonical` | `varchar(255)` | no | canonical room identity |
| `booking_code` | `varchar(128)` | no | OTDS/export room code |
| `room_type` | `varchar(64)` | no | export room type |
| `room_name` | `varchar(255)` | no | human-readable room name |
| `active` | `boolean` | no | lifecycle flag |
| `comment` | `text` | yes | operational note |
| `valid_from` | `date` | yes | optional validity |
| `valid_to` | `date` | yes | optional validity |
| `inserted_at` | `timestamptz` | no | audit |
| `updated_at` | `timestamptz` | no | audit |

## Уникальность

Нужно:

- `unique (provider, hotel_code, provider_room_code_canonical)`

## Индексы

- `(provider, hotel_code, booking_code)`
- `(provider, hotel_code, provider_room_code)`
- `(active)`

## Инварианты

1. canonical room identity уникальна в пределах hotel scope
2. mapping не должен вычисляться writer-ом
3. build/export читают только готовый mapping

