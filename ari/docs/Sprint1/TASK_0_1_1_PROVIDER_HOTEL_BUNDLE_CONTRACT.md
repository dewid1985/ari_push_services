# Sprint 1 - Task 0.1.1

## `ProviderHotelBundle` Generic Contract

Этот документ фиксирует универсальный contract-level слой.

`Synxis` не является здесь центром модели. Он только один из provider profiles, который будет использовать этот контракт.

## Цель

`ProviderHotelBundle` должен быть таким контрактом, чтобы:

- его можно было собрать из любого provider adapter
- его можно было сохранить как immutable snapshot
- его можно было валидировать независимо от downstream build
- его можно было повторно использовать для replay/rebuild

## Generic Contract Schema

```yaml
ProviderHotelBundle:
  bundle_id: UUID
  provider: string
  environment: string
  hotel_code: string
  profile: string
  source_system: string
  source_reference: string | null
  delivery_reference: string | null
  bundle_checksum: string
  checksum_algorithm: string
  version: integer
  status: enum
  status_reason: string | null
  collected_at: datetime
  finalized_at: datetime | null
  validated_at: datetime | null
  invalidated_at: datetime | null
  files: ProviderBundleFile[]
  metadata: map
```

```yaml
ProviderBundleFile:
  document_type: string
  file_name: string
  required: boolean
  storage_kind: enum
  storage_path: string | null
  payload_inline: string | null
  content_type: string
  encoding: string | null
  size_bytes: integer
  checksum: string
  checksum_algorithm: string
  fetched_at: datetime
  source_endpoint: string | null
  request_reference: string | null
  metadata: map
```

## Generic enum values

### `status`

- `collecting`
- `collected`
- `validated`
- `invalid`
- `finalized`
- `rejected`

### `storage_kind`

- `inline_payload`
- `object_storage`
- `archive_entry`

## Generic invariants

1. Один bundle относится к одному `provider`.
2. Один bundle относится к одной `environment`.
3. Один bundle относится к одному `hotel_code`.
4. После `finalized` file list и payload меняться не могут.
5. `bundle_checksum` вычисляется детерминированно из file-level checksums.
6. `invalid -> validated` без новой версии bundle запрещён.
7. Bundle contract не зависит от конкретного формата transport-а.

## Provider profile concept

Поле `profile` нужно для явного указания, по каким правилам bundle должен валидироваться.

Примеры:

- `synxis_hotel_bundle_v1`
- `provider_x_push_bundle_v2`
- `provider_y_poll_bundle_v1`

Именно `profile` определяет:

- какие документы обязательны
- как называются document types
- какие completeness rules применяются
- какие provider-specific validation checks допустимы

## Synxis как provider profile

Для Synxis `profile` может быть:

```text
synxis_hotel_bundle_v1
```

И тогда обязательные document types такие:

- `rates`
- `inventory`
- `availabilities`
- `hotel_descriptive_info`

Canonical filenames:

- `Rates.xml`
- `Inventory.xml`
- `Availabilities.xml`
- `HotelDescriptiveInfo.xml`

Таким образом:

- generic contract остаётся общим
- Synxis только подставляет свой profile и свой набор документов

## Generic uniqueness

Рекомендуемый uniqueness key:

```text
provider + environment + hotel_code + bundle_checksum
```

Если нужен явный profile scope:

```text
provider + environment + hotel_code + profile + bundle_checksum
```

Я бы рекомендовал второй вариант, потому что он безопаснее при эволюции profiles.

## Generic lifecycle

Разрешённые переходы:

```text
collecting -> collected
collecting -> invalid
collected -> validated
collected -> invalid
validated -> finalized
validated -> rejected
invalid -> rejected
```

## Elixir shape

```elixir
%ProviderHotelBundle{
  bundle_id: Ecto.UUID.t(),
  provider: String.t(),
  environment: String.t(),
  hotel_code: String.t(),
  profile: String.t(),
  source_system: String.t(),
  source_reference: String.t() | nil,
  delivery_reference: String.t() | nil,
  bundle_checksum: String.t(),
  checksum_algorithm: String.t(),
  version: pos_integer(),
  status: :collecting | :collected | :validated | :invalid | :finalized | :rejected,
  status_reason: String.t() | nil,
  collected_at: DateTime.t(),
  finalized_at: DateTime.t() | nil,
  validated_at: DateTime.t() | nil,
  invalidated_at: DateTime.t() | nil,
  files: [%ProviderBundleFile{}],
  metadata: %{}
}
```

## Что это даёт архитектурно

После фиксации этого контракта:

- ingestion core становится provider-agnostic
- transport adapters становятся сменными
- replay и observability работают одинаково для всех providers
- downstream canonical/build layer получает унифицированную точку входа

## Следующий слой

Следом нужно зафиксировать provider-specific profile document.

Для текущего проекта это:

- `SynxisHotelBundleProfile`

То есть отдельный документ, где будет перечислено:

- какие документы Synxis обязан дать
- какие filenames считаются canonical
- какие validation checks Synxis profile требует
