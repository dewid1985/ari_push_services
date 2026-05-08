# Sprint 1 README

## Что это

Это короткая входная точка в planning-пакет `Sprint 1`.

Цель спринта:

- зафиксировать модель
- зафиксировать таблицы
- зафиксировать входной контур
- чтобы система умела получить и провалидировать один bundle

Важно:

- core механизм проектируется как универсальный
- `Synxis` используется как reference provider profile

## Что читать в каком порядке

### 1. Сначала общую рамку

1. [`../SYNXIS_RPAC_OTDS_GREENFIELD_SPEC.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/SYNXIS_RPAC_OTDS_GREENFIELD_SPEC.md:1)
2. [`../SYNXIS_RPAC_OTDS_TASKS.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/SYNXIS_RPAC_OTDS_TASKS.md:3482)

### 2. Потом карту Sprint 1

3. [INDEX_SPRINT1.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/INDEX_SPRINT1.md:1)

### 3. Потом foundation

4. [TASK_0_1_PROVIDER_HOTEL_BUNDLE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_1_PROVIDER_HOTEL_BUNDLE.md:1)
5. [TASK_0_1_1_PROVIDER_HOTEL_BUNDLE_CONTRACT.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_1_1_PROVIDER_HOTEL_BUNDLE_CONTRACT.md:1)
6. [TASK_0_1_3_SYNXIS_PROVIDER_PROFILE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_1_3_SYNXIS_PROVIDER_PROFILE.md:1)
7. [TASK_0_5_IDENTIFIER_RULES.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_5_IDENTIFIER_RULES.md:1)
8. [TASK_0_6_EXTERNAL_CODE_SOURCE_OF_TRUTH.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_6_EXTERNAL_CODE_SOURCE_OF_TRUTH.md:1)
9. [TASK_0_7_ERROR_TAXONOMY.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_7_ERROR_TAXONOMY.md:1)
10. [TASK_0_8_STATE_MACHINE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_8_STATE_MACHINE.md:1)

### 4. Потом база

11. [TASK_1_1_PROVIDER_HOTEL_BUNDLE_TABLE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_1_1_PROVIDER_HOTEL_BUNDLE_TABLE.md:1)
12. [TASK_1_2_PROVIDER_RATEPLAN_BOARD_MAPPING.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_1_2_PROVIDER_RATEPLAN_BOARD_MAPPING.md:1)
13. [TASK_1_3_PROVIDER_ROOM_MAPPING.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_1_3_PROVIDER_ROOM_MAPPING.md:1)
14. [TASK_1_4_PROVIDER_BOARD_MAPPING.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_1_4_PROVIDER_BOARD_MAPPING.md:1)
15. [TASK_1_5_RPAC_STORAGE_TABLES.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_1_5_RPAC_STORAGE_TABLES.md:1)
16. [TASK_1_8_MIGRATION_ORDER.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_1_8_MIGRATION_ORDER.md:1)

### 5. Потом legacy boundaries и input layer

17. `2.x` документы
18. `3.x` документы

## Как читать пакет

Если нужна архитектура:

- читай `0.x`

Если нужна схема БД:

- читай `1.x`

Если нужны точки интеграции с legacy:

- читай `2.x`

Если нужен входной transport/orchestration:

- читай `3.x`

## Что здесь не делаем

В этом пакете мы:

- не пишем код
- не делаем миграции
- не реализуем клиентов

Мы только фиксируем:

- контракты
- зависимости
- boundaries
- таблицы
- порядок реализации

## Короткий итог

Если команда читает только три файла, то начать нужно с:

1. [INDEX_SPRINT1.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/INDEX_SPRINT1.md:1)
2. [TASK_0_1_PROVIDER_HOTEL_BUNDLE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_1_PROVIDER_HOTEL_BUNDLE.md:1)
3. [TASK_1_1_PROVIDER_HOTEL_BUNDLE_TABLE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_1_1_PROVIDER_HOTEL_BUNDLE_TABLE.md:1)
