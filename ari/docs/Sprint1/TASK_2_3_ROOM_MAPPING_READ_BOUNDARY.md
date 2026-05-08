# Sprint 1 - Task 2.3

## Реализовать Room Mapping Read Boundary

## Роль boundary

Этот адаптер получает `provider_room_code_canonical` и возвращает `MappedRoom`.

## Что читает

Source of truth:

- `provider_room_mapping`

## Контракт запроса

```yaml
RoomMappingQuery:
  provider: string
  hotel_code: string
  provider_room_code_canonical: string
```

## Контракт ответа

```yaml
MappedRoom:
  provider: string
  hotel_code: string
  provider_room_code: string
  provider_room_code_canonical: string
  booking_code: string
  room_type: string
  room_name: string
```

## Поведение при отсутствии mapping

Boundary сам не invent-ит fallback.

Он должен вернуть:

- `not_found`

Дальше build/export слой уже решает reject semantics по taxonomy.

