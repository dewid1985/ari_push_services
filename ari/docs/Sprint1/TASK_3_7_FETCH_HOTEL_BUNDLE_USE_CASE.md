# Sprint 1 - Task 3.7

## Реализовать `FetchHotelBundle` Use Case

## Роль

Это orchestration use case, который:

1. вызывает APS client
2. вызывает descriptive client
3. собирает `ProviderHotelBundle`
4. сохраняет bundle
5. запускает validation

## Контракт

Input:

- `provider`
- `profile`
- `environment`
- `hotel_code`

Output:

- `{:ok, bundle_id}`
- `{:error, bundle_fetch_error}`

## Правила

1. orchestration не сериализует SOAP вручную
2. orchestration не знает transport header details
3. orchestration знает recipe bundle profile
4. orchestration создаёт один bundle на один hotel scope

