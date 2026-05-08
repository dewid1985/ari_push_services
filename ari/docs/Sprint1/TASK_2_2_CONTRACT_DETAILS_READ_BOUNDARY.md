# Sprint 1 - Task 2.2

## Реализовать read-model boundary для `ContractDetails`

## Роль boundary

Этот адаптер даёт canonical/build слоям чистый lookup:

- `rate_plan_code -> board_code`

Для одного:

- `provider`
- `environment`
- `hotel_code`

## Что читает

Source of truth:

- `provider_rateplan_board_mapping`

## Контракт запроса

```yaml
ContractDetailsQuery:
  provider: string
  environment: string
  hotel_code: string
```

## Контракт ответа

```yaml
ContractDetailsResult:
  provider: string
  environment: string
  hotel_code: string
  mappings:
    - rate_plan_code: string
      board_code: string
```

## Гарантии

1. результат уже отвязан от legacy ORM/table classes
2. параметры нормализованы до provider/environment/hotel scope
3. board resolution deterministic

## Чего boundary не делает

- не парсит XML
- не вычисляет board on the fly
- не знает про export board mapping

