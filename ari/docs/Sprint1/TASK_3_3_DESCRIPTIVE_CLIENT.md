# Sprint 1 - Task 3.3

## Реализовать Descriptive Client

## Роль

Client descriptive endpoint должен:

- принять auth/header
- принять built request
- сделать transport call
- вернуть raw XML response

## Контракт

Input:

- auth/header object
- request payload

Output:

- `{:ok, raw_xml}`
- `{:error, transport_error}`

## Правила

1. client возвращает raw XML, а не parsed domain model
2. faults нормализуются в transport/provider errors
3. client ничего не знает про bundle storage

