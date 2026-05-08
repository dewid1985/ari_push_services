# Sprint 1 - Task 3.6

## Реализовать APS Client

## Роль

APS client должен дать raw transport API:

- `get_rates_raw/1`
- `get_inventory_raw/1`
- `get_availabilities_raw/1`

## Контракт

Input:

- auth config
- request object

Output:

- `{:ok, raw_xml}`
- `{:error, transport_error}`

## Правила

1. config validation отделяется от orchestration
2. raw response methods остаются явными
3. client не пишет bundle и не знает validation rules

