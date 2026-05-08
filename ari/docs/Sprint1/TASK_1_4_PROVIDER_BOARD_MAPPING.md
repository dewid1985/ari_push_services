# Sprint 1 - Task 1.4

## Спроектировать таблицу `provider_board_mapping`

## Роль таблицы

Это source of truth для board export mapping.

Она не заменяет `provider_rateplan_board_mapping`.

Разделение такое:

- `provider_rateplan_board_mapping` отвечает за `rate plan -> board`
- `provider_board_mapping` отвечает за `board -> export-ready board metadata`

## Scope

Минимальный scope:

- `provider`
- `provider_board_code`

## Колонки

| Колонка | Тип | Null | Смысл |
|---|---|---|---|
| `id` | `uuid` | no | PK |
| `provider` | `varchar(64)` | no | provider namespace |
| `provider_board_code` | `varchar(128)` | no | source board code |
| `booking_code` | `varchar(128)` | no | OTDS/export board code |
| `board_type` | `varchar(64)` | no | export board type |
| `board_name` | `varchar(255)` | no | human-readable board name |
| `active` | `boolean` | no | lifecycle flag |
| `comment` | `text` | yes | operational note |
| `inserted_at` | `timestamptz` | no | audit |
| `updated_at` | `timestamptz` | no | audit |

## Уникальность

Нужно:

- `unique (provider, provider_board_code)`

## Индексы

- `(provider, booking_code)`
- `(active)`

## Инварианты

1. board export metadata хранится отдельно от rate-plan mapping
2. writer не должен вычислять `booking_code`
3. один provider board code должен иметь один актуальный export mapping

