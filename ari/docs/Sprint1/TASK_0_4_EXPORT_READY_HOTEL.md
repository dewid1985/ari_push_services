# Sprint 1 - Task 0.4

## Зафиксировать `ExportReadyHotel`

`ExportReadyHotel` это финальная доменная модель, которую уже можно передать writer-слою без дополнительной бизнес-логики.

## Роль

Этот объект отделяет:

- build semantics
- export mapping semantics
- writer serialization

Writer должен только сериализовать `ExportReadyHotel`, а не резолвить mappings или identities.

## Contract shape

```yaml
ExportReadyHotel:
  provider: string
  hotel_code: string
  external_code: string
  rpac_version: integer
  currency: string
  mapped_rooms: list<MappedRoom>
  mapped_boards: list<MappedBoard>
  combinations: list<ExportCombination>
  warnings: list<BuildWarning>
  empty_reason: string | null
```

### `MappedRoom`

```yaml
MappedRoom:
  provider_room_code_canonical: string
  booking_code: string
  room_type: string | null
  room_name: string | null
```

### `MappedBoard`

```yaml
MappedBoard:
  board_code: string
  booking_code: string
  board_type: string | null
  board_name: string | null
```

### `ExportCombination`

```yaml
ExportCombination:
  offer_id: string
  intersection_id: string
  mapped_room_booking_code: string
  mapped_board_booking_code: string
  prices: list<map>
  availabilities: list<map>
  filters: list<map>
```

## Invariants

1. `external_code` обязателен.
2. Writer не получает unmapped rooms или boards.
3. `combinations` не могут ссылаться на missing mappings.
4. Если после mapping/filtering комбинаций нет, hotel считается rejected/empty.

## Source of truth

`external_code` не рождается здесь.

Он должен приходить из:

- hotel matching layer

А не из writer и не из export policy forms.

## Что это разблокирует

После `0.4` можно делать:

- `1.3`, `1.4`
- `1.6`
- `2.5`
- writer tasks `7.x`

