# Sprint 1 Index

## Назначение

Этот индекс собирает в одном месте planning-пакет `Sprint 1`, разложенный на отдельные task-документы.

Он синхронизирован с:

- [`SYNXIS_RPAC_OTDS_GREENFIELD_SPEC.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/SYNXIS_RPAC_OTDS_GREENFIELD_SPEC.md:1)
- [`SYNXIS_RPAC_OTDS_TASKS.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/SYNXIS_RPAC_OTDS_TASKS.md:3482)

## Важная архитектурная оговорка

`Sprint 1` теперь трактуется так:

- core механизм универсальный
- `ProviderHotelBundle` является generic ingestion contract
- `Synxis` является reference provider profile

## Цель Sprint 1

Из [`TASKS.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/SYNXIS_RPAC_OTDS_TASKS.md:3484):

- зафиксировать модель, таблицы и входной контур
- чтобы система умела получить и провалидировать один bundle

## 1. Foundation / Contracts

| Task | Что фиксирует | Depends on | Документ |
|---|---|---|---|
| `0.1` | generic bundle core | - | [TASK_0_1_PROVIDER_HOTEL_BUNDLE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_1_PROVIDER_HOTEL_BUNDLE.md:1) |
| `0.1.1` | bundle contract schema | `0.1` | [TASK_0_1_1_PROVIDER_HOTEL_BUNDLE_CONTRACT.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_1_1_PROVIDER_HOTEL_BUNDLE_CONTRACT.md:1) |
| `0.1.2` | storage mapping for bundle | `0.1.1` | [TASK_0_1_2_PROVIDER_HOTEL_BUNDLE_STORAGE_MAPPING.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_1_2_PROVIDER_HOTEL_BUNDLE_STORAGE_MAPPING.md:1) |
| `0.1.3` | Synxis provider profile | `0.1` | [TASK_0_1_3_SYNXIS_PROVIDER_PROFILE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_1_3_SYNXIS_PROVIDER_PROFILE.md:1) |
| `0.2` | canonical `HotelData` | `0.1` | [TASK_0_2_HOTEL_DATA.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_2_HOTEL_DATA.md:1) |
| `0.3` | `RpacBuildResult` contract | `0.2`, `0.5`, `0.7` | [TASK_0_3_RPAC_BUILD_RESULT.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_3_RPAC_BUILD_RESULT.md:1) |
| `0.4` | `ExportReadyHotel` contract | `0.3`, `0.5`, `0.6` | [TASK_0_4_EXPORT_READY_HOTEL.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_4_EXPORT_READY_HOTEL.md:1) |
| `0.5` | identity policy | `0.2` | [TASK_0_5_IDENTIFIER_RULES.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_5_IDENTIFIER_RULES.md:1) |
| `0.6` | `external_code` source of truth | - | [TASK_0_6_EXTERNAL_CODE_SOURCE_OF_TRUTH.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_6_EXTERNAL_CODE_SOURCE_OF_TRUTH.md:1) |
| `0.7` | error/reject taxonomy | `0.1`, `0.2`, `0.3`, `0.4` | [TASK_0_7_ERROR_TAXONOMY.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_7_ERROR_TAXONOMY.md:1) |
| `0.8` | state machine | `0.1`, `0.3`, `0.4` | [TASK_0_8_STATE_MACHINE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_8_STATE_MACHINE.md:1) |

## 2. DB / Storage

| Task | Что фиксирует | Depends on | Документ |
|---|---|---|---|
| `1.1` | bundle tables | `0.1`, `0.8` | [TASK_1_1_PROVIDER_HOTEL_BUNDLE_TABLE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_1_1_PROVIDER_HOTEL_BUNDLE_TABLE.md:1) |
| `1.2` | `provider_rateplan_board_mapping` | `0.2`, `0.5` | [TASK_1_2_PROVIDER_RATEPLAN_BOARD_MAPPING.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_1_2_PROVIDER_RATEPLAN_BOARD_MAPPING.md:1) |
| `1.3` | `provider_room_mapping` | `0.4`, `0.5` | [TASK_1_3_PROVIDER_ROOM_MAPPING.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_1_3_PROVIDER_ROOM_MAPPING.md:1) |
| `1.4` | `provider_board_mapping` | `0.4`, `0.5` | [TASK_1_4_PROVIDER_BOARD_MAPPING.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_1_4_PROVIDER_BOARD_MAPPING.md:1) |
| `1.5` | RPAC storage tables | `0.3`, `0.8` | [TASK_1_5_RPAC_STORAGE_TABLES.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_1_5_RPAC_STORAGE_TABLES.md:1) |
| `1.8` | migration order | `1.1`–`1.5` | [TASK_1_8_MIGRATION_ORDER.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_1_8_MIGRATION_ORDER.md:1) |

## 3. Legacy Read Boundaries

| Task | Что фиксирует | Depends on | Документ |
|---|---|---|---|
| `2.1` | `HotelMatching` read boundary | `0.6`, `1.8` | [TASK_2_1_HOTEL_MATCHING_READ_BOUNDARY.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_2_1_HOTEL_MATCHING_READ_BOUNDARY.md:1) |
| `2.2` | `ContractDetails` read boundary | `1.2`, `0.5` | [TASK_2_2_CONTRACT_DETAILS_READ_BOUNDARY.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_2_2_CONTRACT_DETAILS_READ_BOUNDARY.md:1) |
| `2.3` | room mapping read boundary | `1.3`, `0.5` | [TASK_2_3_ROOM_MAPPING_READ_BOUNDARY.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_2_3_ROOM_MAPPING_READ_BOUNDARY.md:1) |
| `2.4` | board mapping read boundary | `1.4`, `0.5` | [TASK_2_4_BOARD_MAPPING_READ_BOUNDARY.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_2_4_BOARD_MAPPING_READ_BOUNDARY.md:1) |
| `2.5` | export policy read boundary | `0.6`, `0.4` | [TASK_2_5_EXPORT_POLICY_READ_BOUNDARY.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_2_5_EXPORT_POLICY_READ_BOUNDARY.md:1) |

## 4. Input Layer

| Task | Что фиксирует | Depends on | Документ |
|---|---|---|---|
| `3.1` | descriptive auth builder | `0.1` | [TASK_3_1_DESCRIPTIVE_SOAP_AUTH_BUILDER.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_3_1_DESCRIPTIVE_SOAP_AUTH_BUILDER.md:1) |
| `3.2` | descriptive request builder | `3.1` | [TASK_3_2_DESCRIPTIVE_REQUEST_BUILDER.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_3_2_DESCRIPTIVE_REQUEST_BUILDER.md:1) |
| `3.3` | descriptive client | `3.1`, `3.2` | [TASK_3_3_DESCRIPTIVE_CLIENT.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_3_3_DESCRIPTIVE_CLIENT.md:1) |
| `3.4` | APS auth builder | `0.1` | [TASK_3_4_APS_AUTH_BUILDER.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_3_4_APS_AUTH_BUILDER.md:1) |
| `3.5` | APS request builders | `3.4` | [TASK_3_5_APS_REQUEST_BUILDERS.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_3_5_APS_REQUEST_BUILDERS.md:1) |
| `3.6` | APS client | `3.4`, `3.5` | [TASK_3_6_APS_CLIENT.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_3_6_APS_CLIENT.md:1) |
| `3.7` | `FetchHotelBundle` use case | `3.3`, `3.6`, `1.1` | [TASK_3_7_FETCH_HOTEL_BUNDLE_USE_CASE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_3_7_FETCH_HOTEL_BUNDLE_USE_CASE.md:1) |
| `3.9` | bundle validation service | `0.1`, `0.7`, `3.7` | [TASK_3_9_BUNDLE_VALIDATION_SERVICE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_3_9_BUNDLE_VALIDATION_SERVICE.md:1) |

## Главная dependency chain

### Core chain

`0.1 -> 0.2 -> 0.5 -> 0.3 -> 0.4`

### Storage chain

`0.1 + 0.8 -> 1.1 -> 1.8`

### Mapping chain

`0.5 -> 1.2/1.3/1.4 -> 2.2/2.3/2.4`

### Export identity chain

`0.6 -> 2.1/2.5 -> 0.4`

### Input chain

`0.1 -> 3.1 -> 3.2 -> 3.3`

`0.1 -> 3.4 -> 3.5 -> 3.6`

`3.3 + 3.6 + 1.1 -> 3.7 -> 3.9`

## Что сознательно не входит

Из backlog `Sprint 1` не включены:

- `1.6`
- `1.7`
- `2.6`
- `3.8`

Причина:

- они либо явно вне MVP-пула,
- либо не входят в список задач `MVP Sprint 1`.

## Замеченные коллизии

### 1. Generic vs Synxis naming

В master docs местами ещё используется Synxis-centric naming:

- `SynxisHotelBundle`
- `synxis_hotel_bundle`

В `Sprint1` planning пакет это уже синхронизировано как:

- `ProviderHotelBundle`
- `provider_hotel_bundle`
- `Synxis` как provider profile

### 2. `1.8` vs MVP exclusions

В `TASKS.md` `1.8` зависит от `1.6` и `1.7`, но они одновременно вынесены за пределы MVP.

В Sprint1 docs это разрулено через:

- полный migration order
- отдельный MVP migration order

## Итог

Пакет `Sprint 1` теперь покрывает:

- contracts
- identity
- source of truth
- taxonomy
- lifecycle
- storage
- read boundaries
- input orchestration

Этого достаточно, чтобы потом перейти к реализации без повторного проектирования базовых сущностей.
