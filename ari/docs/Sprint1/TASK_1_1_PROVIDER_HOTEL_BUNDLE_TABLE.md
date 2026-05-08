# Sprint 1 - Task 1.1

## Финальная DB-спецификация для Bundle Storage

Этот документ продолжает:

- [`SYNXIS_RPAC_OTDS_GREENFIELD_SPEC.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/SYNXIS_RPAC_OTDS_GREENFIELD_SPEC.md:1)
- [`SYNXIS_RPAC_OTDS_TASKS.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/SYNXIS_RPAC_OTDS_TASKS.md:509)
- [TASK_0_1_PROVIDER_HOTEL_BUNDLE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_1_PROVIDER_HOTEL_BUNDLE.md:1)
- [TASK_0_1_1_PROVIDER_HOTEL_BUNDLE_CONTRACT.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_1_1_PROVIDER_HOTEL_BUNDLE_CONTRACT.md:1)
- [TASK_0_1_2_PROVIDER_HOTEL_BUNDLE_STORAGE_MAPPING.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_1_2_PROVIDER_HOTEL_BUNDLE_STORAGE_MAPPING.md:1)
- [TASK_0_1_3_SYNXIS_PROVIDER_PROFILE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_1_3_SYNXIS_PROVIDER_PROFILE.md:1)

## Важное решение по именованию

В исходном backlog задача `1.1` названа как:

- `Спроектировать таблицу synxis_hotel_bundle`

Но после уточнения архитектуры видно, что core механизм должен быть универсальным.

Поэтому рекомендованное решение такое:

- generic core table: `provider_hotel_bundle`
- generic child table: `provider_hotel_bundle_file`

`Synxis` при этом остаётся provider profile, а не именем core-таблицы.

Если команде по организационным причинам нужно сохранить старое имя `synxis_hotel_bundle`, это допустимо только как временный компромисс. Архитектурно правильнее сразу делать generic names.

## Цель задачи 1.1

Спроектировать storage schema для immutable bundle snapshots так, чтобы она:

- поддерживала generic ingestion core
- поддерживала provider profiles
- покрывала текущий Synxis profile
- поддерживала replay, dedup, observability и versioning

## Scope таблиц

Для задачи `1.1` нужны две таблицы:

1. `provider_hotel_bundle`
2. `provider_hotel_bundle_file`

Этого достаточно для Sprint 1.

Дополнительные execution/replay таблицы можно проектировать позже.

## Таблица `provider_hotel_bundle`

### Назначение

Bundle-level metadata и lifecycle snapshot.

### Колонки

| Колонка | Тип | Null | Описание |
|---|---|---|---|
| `id` | `uuid` | no | primary key bundle |
| `provider` | `varchar(64)` | no | provider key, например `synxis` |
| `profile` | `varchar(128)` | no | provider bundle profile, например `synxis_hotel_bundle_v1` |
| `environment` | `varchar(32)` | no | `prod`, `stage`, `test`, `dev` |
| `source_system` | `varchar(64)` | no | система-источник |
| `hotel_code` | `varchar(128)` | no | provider hotel code |
| `source_reference` | `varchar(255)` | yes | внешний reference/id при наличии |
| `delivery_reference` | `varchar(255)` | yes | reference orchestration/delivery run |
| `bundle_checksum` | `varchar(255)` | no | aggregate checksum bundle |
| `checksum_algorithm` | `varchar(32)` | no | обычно `sha256` |
| `version` | `integer` | no | bundle version внутри `provider+profile+environment+hotel_code` |
| `status` | `varchar(32)` | no | lifecycle status |
| `status_reason` | `text` | yes | human-readable причина отказа/состояния |
| `file_count` | `integer` | no | число файлов в bundle |
| `collected_at` | `timestamptz` | no | когда bundle полностью собран |
| `finalized_at` | `timestamptz` | yes | когда bundle финализирован |
| `validated_at` | `timestamptz` | yes | когда bundle валидирован |
| `invalidated_at` | `timestamptz` | yes | когда bundle признан invalid |
| `metadata` | `jsonb` | no | bundle-level provenance/debug metadata |
| `inserted_at` | `timestamptz` | no | audit timestamp |
| `updated_at` | `timestamptz` | no | audit timestamp |

### Обязательные check constraints

1. `provider <> ''`
2. `profile <> ''`
3. `environment <> ''`
4. `hotel_code <> ''`
5. `version > 0`
6. `file_count >= 0`
7. `status in ('collecting','collected','validated','invalid','finalized','rejected')`

### Уникальность

Нужны два уникальных ограничения:

1. `unique (provider, profile, environment, hotel_code, bundle_checksum)`
2. `unique (provider, profile, environment, hotel_code, version)`

Смысл:

- одно и то же содержимое не создаётся повторно бессмысленно
- каждая новая версия bundle уникальна в пределах provider/profile/hotel scope

### Индексы

Нужны:

1. `index (provider, profile, environment, hotel_code)`
2. `index (status, collected_at desc)`
3. `index (bundle_checksum)`
4. `index (delivery_reference)`
5. `index (source_reference)`

## Таблица `provider_hotel_bundle_file`

### Назначение

File-level metadata по каждому документу внутри bundle.

### Колонки

| Колонка | Тип | Null | Описание |
|---|---|---|---|
| `id` | `uuid` | no | primary key |
| `bundle_id` | `uuid` | no | FK на bundle |
| `document_type` | `varchar(128)` | no | logical document type |
| `file_name` | `varchar(255)` | no | canonical file name |
| `required` | `boolean` | no | required/optional по profile |
| `storage_kind` | `varchar(32)` | no | `inline_payload`, `object_storage`, `archive_entry` |
| `storage_path` | `text` | yes | путь во внешнем storage |
| `payload_inline` | `text` | yes | raw payload, если хранится inline |
| `content_type` | `varchar(128)` | no | обычно `application/xml` |
| `encoding` | `varchar(32)` | yes | например `utf-8` |
| `size_bytes` | `bigint` | no | размер payload |
| `checksum` | `varchar(255)` | no | file-level checksum |
| `checksum_algorithm` | `varchar(32)` | no | обычно `sha256` |
| `fetched_at` | `timestamptz` | no | время получения документа |
| `source_endpoint` | `varchar(255)` | yes | endpoint или transport operation |
| `request_reference` | `varchar(255)` | yes | correlation/request id |
| `metadata` | `jsonb` | no | file-level metadata |
| `inserted_at` | `timestamptz` | no | audit timestamp |
| `updated_at` | `timestamptz` | no | audit timestamp |

### Обязательные check constraints

1. `document_type <> ''`
2. `file_name <> ''`
3. `size_bytes >= 0`
4. `checksum <> ''`
5. `storage_kind in ('inline_payload','object_storage','archive_entry')`

### Уникальность

Нужны:

1. `unique (bundle_id, document_type)`
2. `unique (bundle_id, file_name)`

### Foreign key

```text
bundle_id -> provider_hotel_bundle.id on delete cascade
```

### Индексы

Нужны:

1. `index (bundle_id)`
2. `index (document_type)`
3. `index (checksum)`
4. `index (request_reference)`

## Связь с Synxis profile

Для текущего Synxis profile таблицы должны без специальных исключений поддерживать:

### Bundle row

```yaml
provider: synxis
profile: synxis_hotel_bundle_v1
environment: prod|stage|test|dev
hotel_code: external provider hotel code
file_count: 4
```

### File rows

```yaml
document_types:
  - rates
  - inventory
  - availabilities
  - hotel_descriptive_info
```

Canonical filenames:

```yaml
rates: Rates.xml
inventory: Inventory.xml
availabilities: Availabilities.xml
hotel_descriptive_info: HotelDescriptiveInfo.xml
```

То есть:

- generic schema не знает Synxis-логики напрямую
- но полностью её покрывает через `provider/profile/document_type`

## Что хранить в `metadata`

### Bundle-level metadata

Рекомендуемо:

- `retry_count`
- `transport_profile`
- `delivery_mode`
- `legacy_delivery_reference`
- `collector_host`

### File-level metadata

Рекомендуемо:

- `transport_adapter`
- `request_operation`
- `response_root_element`
- `response_namespace`

## Что нельзя делать

Не надо:

1. хранить 4 payload-поля прямо в bundle-таблице
2. жёстко зашивать Synxis в имя основной таблицы
3. использовать zip file path как business identity bundle
4. разрешать mutable update file list после `finalized`
5. смешивать lifecycle bundle и lifecycle RPAC build в одной таблице

## Предпочтительная стратегия хранения payload

### Для MVP

Допустимо:

- `payload_inline`

### Для production-цели

Предпочтительно:

- `storage_path` во внешнем storage
- в БД только metadata и checksum

Причина:

- проще retention
- проще observability
- проще replay
- меньше нагрузка на основную БД

## Черновой DDL

```sql
create table provider_hotel_bundle (
  id uuid primary key,
  provider varchar(64) not null,
  profile varchar(128) not null,
  environment varchar(32) not null,
  source_system varchar(64) not null,
  hotel_code varchar(128) not null,
  source_reference varchar(255) null,
  delivery_reference varchar(255) null,
  bundle_checksum varchar(255) not null,
  checksum_algorithm varchar(32) not null,
  version integer not null,
  status varchar(32) not null,
  status_reason text null,
  file_count integer not null,
  collected_at timestamptz not null,
  finalized_at timestamptz null,
  validated_at timestamptz null,
  invalidated_at timestamptz null,
  metadata jsonb not null default '{}'::jsonb,
  inserted_at timestamptz not null,
  updated_at timestamptz not null,
  unique (provider, profile, environment, hotel_code, bundle_checksum),
  unique (provider, profile, environment, hotel_code, version)
);

create index provider_hotel_bundle_scope_idx
  on provider_hotel_bundle(provider, profile, environment, hotel_code);

create index provider_hotel_bundle_status_collected_idx
  on provider_hotel_bundle(status, collected_at desc);

create index provider_hotel_bundle_checksum_idx
  on provider_hotel_bundle(bundle_checksum);

create table provider_hotel_bundle_file (
  id uuid primary key,
  bundle_id uuid not null references provider_hotel_bundle(id) on delete cascade,
  document_type varchar(128) not null,
  file_name varchar(255) not null,
  required boolean not null,
  storage_kind varchar(32) not null,
  storage_path text null,
  payload_inline text null,
  content_type varchar(128) not null,
  encoding varchar(32) null,
  size_bytes bigint not null,
  checksum varchar(255) not null,
  checksum_algorithm varchar(32) not null,
  fetched_at timestamptz not null,
  source_endpoint varchar(255) null,
  request_reference varchar(255) null,
  metadata jsonb not null default '{}'::jsonb,
  inserted_at timestamptz not null,
  updated_at timestamptz not null,
  unique (bundle_id, document_type),
  unique (bundle_id, file_name)
);

create index provider_hotel_bundle_file_bundle_idx
  on provider_hotel_bundle_file(bundle_id);

create index provider_hotel_bundle_file_document_type_idx
  on provider_hotel_bundle_file(document_type);

create index provider_hotel_bundle_file_checksum_idx
  on provider_hotel_bundle_file(checksum);
```

## Acceptance criteria для закрытия 1.1

Задачу `1.1` можно считать закрытой, если:

1. есть окончательное решение по generic именованию таблиц
2. bundle-level и file-level metadata разделены
3. определены все PK/FK/unique constraints
4. зафиксированы lifecycle-compatible статусы
5. схема покрывает текущий Synxis profile без специальных костылей
6. схема пригодна для replay и dedup

## Следующий шаг

После этого можно переходить к:

1. Ecto schema drafts
2. migration order из `1.8`
3. `FetchHotelBundle` persistence flow
