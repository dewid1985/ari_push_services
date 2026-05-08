# Sprint 1 - Task 0.6

## Зафиксировать `External Code` Source Of Truth

## Главное решение

Master source of truth для OTDS hotel identity:

- `hotel_matching.external_code`

Не source of truth:

- `ExportSeasonsHotelOtds.external_hotel_code`
- writer config
- export policy rows

## Семантика

### `hotel_code`

- provider hotel identity

### `external_code`

- OTDS/export identity

Они не взаимозаменяемы.

## Lookup semantics

`external_hotel_code` в policy-слое должен трактоваться только как:

- lookup key на hotel matching

Но не как место, где рождается master identity.

## Export selection dependency

Export selection должен зависеть от:

- hotel matching status
- наличия непустого `external_code`
- export flags / eligibility policy

## Invariants

1. `HotelCandidate` не существует без non-empty `external_code`.
2. Writer не вычисляет `external_code`.
3. Input layer не знает `external_code` как master identity.
4. Mapping/export layers только читают уже определённый `external_code`.

## Что это разблокирует

После `0.6` можно:

- строить `ExportReadyHotel`
- делать `2.1`
- делать `2.5`
- делать hotel selection/export tasks

