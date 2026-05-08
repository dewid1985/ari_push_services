# Sprint 1 - Task 2.4

## Реализовать Board Mapping Read Boundary

## Роль boundary

Этот адаптер получает canonical `board_code` и возвращает `MappedBoard`.

## Что читает

Source of truth:

- `provider_board_mapping`

## Контракт запроса

```yaml
BoardMappingQuery:
  provider: string
  board_code: string
```

## Контракт ответа

```yaml
MappedBoard:
  provider: string
  provider_board_code: string
  booking_code: string
  board_type: string
  board_name: string
```

## Поведение при отсутствии mapping

Boundary возвращает:

- `not_found`

И не пытается строить surrogate export board.

