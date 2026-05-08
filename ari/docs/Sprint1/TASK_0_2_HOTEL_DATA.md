# Sprint 1 - Task 0.2

## Зафиксировать `HotelData`

Этот документ продолжает:

- [TASK_0_1_PROVIDER_HOTEL_BUNDLE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_1_PROVIDER_HOTEL_BUNDLE.md:1)
- [TASK_0_5_IDENTIFIER_RULES.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_5_IDENTIFIER_RULES.md:1)

## Роль `HotelData`

`HotelData` это canonical snapshot по одному отелю после:

- bundle validation
- parsing
- provider-specific extraction
- mapping-assisted canonicalization

Он ещё не является RPAC.

Он должен быть чистой структурой данных, из которой build-слой может детерминированно построить RPAC без доступа к raw XML и без живых запросов во внешние источники.

## Что нельзя тащить в `HotelData`

Нельзя держать внутри:

- `DOMXPath`
- XML-aware helper objects
- transport clients
- lazy lookup в legacy services
- writer/export logic

## Contract shape

```yaml
HotelData:
  provider: string
  profile: string
  environment: string
  hotel_code: string
  bundle_id: uuid
  currency: string
  rate_plans: list<RatePlan>
  rooms: list<Room>
  boards: list<Board>
  descriptive_rooms: list<string>
  child_policy: ChildPolicy
  occupancy_constraints: list<OccupancyConstraint>
  mapping_metadata: map
```

### `RatePlan`

```yaml
RatePlan:
  code: string
  board_code: string
  room_codes: list<string>
  metadata: map
```

### `Room`

```yaml
Room:
  provider_room_code: string
  provider_room_code_canonical: string
  name: string | null
  metadata: map
```

### `Board`

```yaml
Board:
  provider_board_code: string | null
  board_code: string
  name: string | null
  metadata: map
```

## Инварианты

1. Один `HotelData` относится к одному `bundle_id`.
2. Один `HotelData` относится к одному `hotel_code`.
3. `currency` одна на весь `HotelData`.
4. `rate_plan.code` уникален в пределах отеля.
5. `room.provider_room_code_canonical` уникален в пределах отеля.
6. `board.board_code` уникален в пределах отеля.
7. Все `rate_plan.room_codes` ссылаются на существующие canonical rooms.
8. Все `rate_plans` имеют уже resolved `board_code`.

## Age semantics

В `HotelData` должна быть уже нормализованная модель:

- adult/child boundaries
- min/max age
- age qualifying semantics

Build layer не должен заново выводить эти правила из raw XML.

## Occupancy constraints

`HotelData` должен содержать итоговые occupancy facts, а не просто сырой XML fragment.

Например:

- min pax
- max pax
- adult constraints
- child constraints
- room-level restrictions

## Synxis-specific interpretation

Для Synxis:

- source bundle даёт `Rates`, `Inventory`, `Availabilities`, `HotelDescriptiveInfo`
- canonical layer вытягивает rate plans, rooms, occupancy, descriptive whitelist
- mapping layer already resolves board code

То есть Synxis profile наполняет общий `HotelData` contract, но не меняет его форму.

## Что это разблокирует

После фиксации `HotelData` можно без догадок делать:

- `0.3` `RpacBuildResult`
- `1.2` `provider_rateplan_board_mapping`
- `4.4` rate plan extraction
- `4.5` room extraction

