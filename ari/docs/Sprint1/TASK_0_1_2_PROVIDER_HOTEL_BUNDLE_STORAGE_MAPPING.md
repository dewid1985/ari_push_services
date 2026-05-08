# Sprint 1 - Task 0.1.2

## Storage Mapping: `ProviderHotelBundle`

Этот документ переводит generic контракт `ProviderHotelBundle` в универсальную storage-модель.

Идея та же:

- core storage generic
- provider profile specific rules поверх него

## Базовая модель

Для универсального механизма storage должен быть двухуровневым:

1. bundle-level metadata
2. file-level metadata

Рекомендуемые таблицы:

- `provider_hotel_bundle`
- `provider_hotel_bundle_file`

Важно:

- Synxis-specific таблицы не нужны на уровне ingestion core
- Synxis будет одной записью в `provider` и одним `profile`

## Таблица `provider_hotel_bundle`

### Назначение

Хранит:

- identity
- lifecycle
- versioning
- aggregate checksum
- provider scope
- bundle-level metadata

### Поля

```yaml
provider_hotel_bundle:
  id: uuid pk
  provider: varchar not null
  profile: varchar not null
  environment: varchar not null
  source_system: varchar not null
  hotel_code: varchar not null
  source_reference: varchar null
  delivery_reference: varchar null
  bundle_checksum: varchar not null
  checksum_algorithm: varchar not null
  version: integer not null
  status: varchar not null
  status_reason: text null
  file_count: integer not null
  collected_at: timestamptz not null
  finalized_at: timestamptz null
  validated_at: timestamptz null
  invalidated_at: timestamptz null
  metadata: jsonb not null default '{}'
  inserted_at: timestamptz not null
  updated_at: timestamptz not null
```

## Таблица `provider_hotel_bundle_file`

### Назначение

Хранит:

- file-level identity
- document type
- storage reference
- checksum
- provenance

### Поля

```yaml
provider_hotel_bundle_file:
  id: uuid pk
  bundle_id: uuid not null fk -> provider_hotel_bundle.id
  document_type: varchar not null
  file_name: varchar not null
  required: boolean not null
  storage_kind: varchar not null
  storage_path: text null
  payload_inline: text null
  content_type: varchar not null
  encoding: varchar null
  size_bytes: bigint not null
  checksum: varchar not null
  checksum_algorithm: varchar not null
  fetched_at: timestamptz not null
  source_endpoint: varchar null
  request_reference: varchar null
  metadata: jsonb not null default '{}'
  inserted_at: timestamptz not null
  updated_at: timestamptz not null
```

## Почему это generic

Такая storage-модель не привязана к Synxis.

Она одинаково подходит для:

- polling providers
- push providers
- SOAP/XML providers
- JSON/API providers
- providers с 2 файлами
- providers с 4 файлами
- providers с 7 файлами

Разница будет только в:

- `provider`
- `profile`
- списке `document_type`
- validation rules

## Generic constraints

### Для `provider_hotel_bundle`

Нужны:

1. `primary key (id)`
2. `check (file_count >= 0)`
3. `check (version > 0)`
4. `check (status in (...))`
5. `unique (provider, profile, environment, hotel_code, bundle_checksum)`
6. `unique (provider, profile, environment, hotel_code, version)`

### Для `provider_hotel_bundle_file`

Нужны:

1. `primary key (id)`
2. `foreign key (bundle_id) references provider_hotel_bundle(id) on delete cascade`
3. `check (size_bytes >= 0)`
4. `check (storage_kind in (...))`
5. `unique (bundle_id, document_type)`
6. `unique (bundle_id, file_name)`

## Generic indexes

### `provider_hotel_bundle`

- `(provider, profile, environment, hotel_code)`
- `(status, collected_at desc)`
- `(bundle_checksum)`
- `(delivery_reference)`
- `(source_reference)`

### `provider_hotel_bundle_file`

- `(bundle_id)`
- `(document_type)`
- `(checksum)`
- `(request_reference)`

## Что задаётся profile-слоем, а не storage core

Storage-модель не должна знать:

- что для Synxis обязательны именно 4 XML
- что `rates` должен называться `Rates.xml`
- что другой provider обязан прислать `Rooms.json`

Это должно жить в provider profile spec.

Storage core должен знать только:

- у bundle есть files
- у files есть type/name/checksum/storage
- у bundle есть lifecycle и identity

## Synxis profile в этой модели

Для Synxis это будет просто такая конфигурация:

```yaml
provider: synxis
profile: synxis_hotel_bundle_v1
required_document_types:
  - rates
  - inventory
  - availabilities
  - hotel_descriptive_info
canonical_filenames:
  rates: Rates.xml
  inventory: Inventory.xml
  availabilities: Availabilities.xml
  hotel_descriptive_info: HotelDescriptiveInfo.xml
```

То есть в generic storage никакой отдельной Synxis-таблицы не требуется.

## Почему это лучше, чем `synxis_hotel_bundle`

Если ingestion core строится как универсальный:

- нельзя жёстко зашивать provider в имя таблицы
- нельзя хранить provider-specific payload columns в bundle row
- нельзя проектировать bundle storage так, будто в системе всегда только 4 XML

Поэтому на уровне core правильнее:

- `provider_hotel_bundle`
- `provider_hotel_bundle_file`

А уже если потом нужны provider-specific read models, они строятся отдельно.

## Что делать с raw payload

Рекомендуемая стратегия:

- bundle metadata в БД
- file metadata в БД
- raw payload предпочтительно во внешнем storage

Для MVP допустимы два режима:

1. `payload_inline`
2. `storage_path`

Но contract и schema должны поддерживать оба.

## Derived fields

Лучше системно вычислять:

- `bundle_checksum`
- `file_count`
- `size_bytes`
- `version`

И не принимать их как доверенный внешний input.

## DDL direction

```sql
create table provider_hotel_bundle (
  id uuid primary key,
  provider varchar not null,
  profile varchar not null,
  environment varchar not null,
  source_system varchar not null,
  hotel_code varchar not null,
  source_reference varchar null,
  delivery_reference varchar null,
  bundle_checksum varchar not null,
  checksum_algorithm varchar not null,
  version integer not null,
  status varchar not null,
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

create table provider_hotel_bundle_file (
  id uuid primary key,
  bundle_id uuid not null references provider_hotel_bundle(id) on delete cascade,
  document_type varchar not null,
  file_name varchar not null,
  required boolean not null,
  storage_kind varchar not null,
  storage_path text null,
  payload_inline text null,
  content_type varchar not null,
  encoding varchar null,
  size_bytes bigint not null,
  checksum varchar not null,
  checksum_algorithm varchar not null,
  fetched_at timestamptz not null,
  source_endpoint varchar null,
  request_reference varchar null,
  metadata jsonb not null default '{}'::jsonb,
  inserted_at timestamptz not null,
  updated_at timestamptz not null,
  unique (bundle_id, document_type),
  unique (bundle_id, file_name)
);
```

## Что это разблокирует

После этого можно уже корректно делать:

1. generic ingestion schema
2. generic Ecto schemas
3. provider profile specs
4. provider-specific adapters

## Следующий правильный документ

Следом нужно сделать provider profile doc для Synxis:

- `TASK_0_1_3_SYNXIS_PROVIDER_PROFILE.md`

Там уже надо зафиксировать:

- обязательные документы Synxis
- transport endpoints
- canonical filenames
- provider-specific completeness и validation rules
