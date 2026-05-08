# Sprint 1 - Task 2.5

## Реализовать Export Policy Read Boundary

## Роль boundary

Этот адаптер читает hotel-level export policy после того, как hotel уже selected и уже имеет `external_code`.

## Что читает

Source:

- export policy records keyed by `external_hotel_code`

## Контракт запроса

```yaml
ExportPolicyQuery:
  external_code: string
  operator_id: integer | null
  source_market_id: integer | null
```

## Контракт ответа

```yaml
ExportPolicy:
  external_code: string
  offers_start_min_days: integer | null
  offers_start_max_days: integer | null
  season_date_min: date | null
  season_date_max: date | null
  adults_max: integer | null
  children_max: integer | null
  travel_durations: list<integer>
  travel_type: list<string>
  operator_scope: integer | null
```

## Priority / merge semantics

Нужно зафиксировать отдельно:

1. как комбинируются несколько policy records
2. какой policy выигрывает при конфликте
3. что происходит при отсутствии policy

Минимальная гарантия:

- boundary возвращает deterministic merged view

## Чего boundary не делает

- не выбирает hotel candidate
- не знает writer format
- не выполняет export filtering сам
