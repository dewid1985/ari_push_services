# Sprint 1 - Task 3.2

## Реализовать Descriptive Request Builder

## Роль

Отдельно от client execution собрать `HotelDescriptiveInfoRQ`.

## Контракт

Input:

- `hotel_code`
- profile config по sections

Output:

- raw request payload или request DTO для descriptive operation

## Правила

1. builder определяет какие sections запрашиваются
2. execution client не решает domain shape request-а
3. orchestration не сериализует request вручную

