# Sprint 1 - Task 3.5

## Реализовать APS Request Builders

## Роль

Нужны три отдельные explicit operations:

- `getRates`
- `getInventory`
- `getAvailabilities`

## Контракт

Input:

- `hotel_code`

Output:

- request payload/DTO для соответствующей APS operation

## Правила

1. shared envelope parts можно переиспользовать
2. operations остаются явными и не прячутся в одну generic string-based функцию
3. builder не выполняет transport call

