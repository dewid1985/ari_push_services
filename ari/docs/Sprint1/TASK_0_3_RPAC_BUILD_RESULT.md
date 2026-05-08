# Sprint 1 - Task 0.3

## Зафиксировать `RpacBuildResult`

Этот документ описывает результат build-слоя между `HotelData` и export-ready слоем.

## Роль

`RpacBuildResult` должен быть:

- детерминированным
- immutable
- versioned через `rpac_version`
- пригодным для observability и replay

## Contract shape

```yaml
RpacBuildResult:
  provider: string
  hotel_code: string
  bundle_id: uuid
  version: integer
  currency: string
  offers: list<RpacOffer>
  warnings: list<BuildWarning>
  rejects: list<BuildReject>
  stats: BuildStats
```

### `RpacOffer`

```yaml
RpacOffer:
  offer_id: string
  rate_plan_code: string
  board_code: string
  intersections: list<RpacIntersection>
```

### `RpacIntersection`

```yaml
RpacIntersection:
  intersection_id: string
  room_code_canonical: string
  board_code: string
  occupancies: list<map>
  prices: list<RpacPrice>
  availabilities: list<RpacAvailability>
  filters: list<RpacFilter>
```

## Identity rules

- `offer_id = hotel_code + rate_plan_code + board_code`
- `intersection_id = offer_id + room_code_canonical`

## Invariants

1. `currency` одна на весь build result.
2. `offers` может быть пустым только если build завершился terminal reject.
3. Все intersections используют уже canonical room identity.
4. Build layer не мутирует identity после сборки intersections.

## Warnings / Rejects / Stats

Build result обязан содержать:

- warnings
- rejects
- stats

Минимальные stats:

- `offers_count`
- `intersections_count`
- `prices_count`
- `availabilities_count`
- `warnings_count`
- `rejects_count`

## Synxis-specific interpretation

Для Synxis processors legacy уже логически разделены:

- inventories
- availabilities
- rates

Но итоговый result в legacy формально не зафиксирован. Этот документ как раз фиксирует конечный shape, в который все эти processors должны собираться.

## Что это разблокирует

После `0.3` можно нормально делать:

- `0.4` `ExportReadyHotel`
- `1.5` RPAC storage tables
- `5.1`+ build-layer tasks

