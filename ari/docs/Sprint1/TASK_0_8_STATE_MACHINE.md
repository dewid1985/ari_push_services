# Sprint 1 - Task 0.8

## Зафиксировать state machine по ключевым сущностям

## Bundle lifecycle

Допустимые статусы:

- `collecting`
- `collected`
- `validated`
- `invalid`
- `finalized`
- `rejected`

Переходы:

1. `collecting -> collected`
2. `collecting -> invalid`
3. `collected -> validated`
4. `collected -> invalid`
5. `validated -> finalized`
6. `validated -> rejected`
7. `invalid -> rejected`

Нельзя:

- `invalid -> validated` без новой версии
- `finalized -> collecting`

## RPAC lifecycle

Допустимые статусы:

- `build_pending`
- `building`
- `built`
- `rejected`
- `mapped`
- `exported`
- `failed`

Переходы:

1. `build_pending -> building`
2. `building -> built`
3. `building -> rejected`
4. `building -> failed`
5. `built -> mapped`
6. `mapped -> exported`

## Export lifecycle

Минимально:

- `export_pending`
- `exporting`
- `exported`
- `failed`
- `rejected`

## Replay / versioning rules

1. Новый bundle создаёт новую bundle version.
2. Новый build создаёт новую `rpac_version`.
3. Replay не мутирует старый snapshot.
4. Export rerun должен быть идемпотентен в пределах одной `rpac_version`.

## Freeze points

- bundle immutable после `finalized`
- RPAC immutable после `built`
- export artifact immutable после `exported`

## Что это разблокирует

После `0.8` можно:

- финализировать bundle/RPAC/export таблицы
- писать migration statuses
- проектировать replay flow
