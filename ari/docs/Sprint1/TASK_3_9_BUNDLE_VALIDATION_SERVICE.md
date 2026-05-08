# Sprint 1 - Task 3.9

## Реализовать Bundle Validation Service

## Роль

Проверить freshly fetched bundle до canonical layer.

## Минимальные проверки

1. presence required files
2. non-empty payload
3. valid XML structure
4. hotel consistency across files
5. profile completeness rules

## Контракт

Input:

- `ProviderHotelBundle`
- provider profile rules

Output:

- `{:ok, validated_bundle}`
- `{:error, validation_errors}`

## Результат

Сервис обязан сохранить:

- validation status
- validation timestamps
- machine-readable error codes

## Правила

1. validator не строит `HotelData`
2. validator не делает transport retry
3. validator использует taxonomy из `0.7`
