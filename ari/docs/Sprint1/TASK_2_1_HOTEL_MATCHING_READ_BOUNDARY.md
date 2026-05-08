# Sprint 1 - Task 2.1

## Реализовать read-model boundary для `HotelMatching`

## Роль boundary

Этот адаптер даёт exportable hotel selection surface.

Он не должен раскрывать calling code детали legacy-таблиц или UI-форм.

## Что читает

Source of truth:

- `hotel_matching`

Ключевые поля:

- `provider`
- `hotel_code`
- `external_code`
- `export`
- `status`
- `operator_id`
- `source_market_id`

## Что возвращает

```yaml
ExportableHotelCandidate:
  provider: string
  hotel_code: string
  external_code: string
  operator_id: integer | null
  source_market_id: integer | null
  export_enabled: boolean
  status: string
```

## Гарантии

1. `external_code` непустой
2. hotel уже прошёл exportability filter
3. порядок сортировки детерминированный

## Порядок

Сортировка по `external_code` важна и должна быть частью контракта.

## Чего boundary не делает

- не строит `ExportReadyHotel`
- не читает policies
- не делает RPAC build

