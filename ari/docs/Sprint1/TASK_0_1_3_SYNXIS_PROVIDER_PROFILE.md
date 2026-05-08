# Sprint 1 - Task 0.1.3

## `SynxisProviderProfile` для `ProviderHotelBundle`

Этот документ нужно читать строго в контексте:

- [`SYNXIS_RPAC_OTDS_GREENFIELD_SPEC.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/SYNXIS_RPAC_OTDS_GREENFIELD_SPEC.md:1)
- [`SYNXIS_RPAC_OTDS_TASKS.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/SYNXIS_RPAC_OTDS_TASKS.md:1)

Он не заменяет generic ingestion contract.

Его роль:

- взять универсальный `ProviderHotelBundle`
- и зафиксировать, как именно `Synxis` наполняет этот контракт

## Зачем нужен отдельный provider profile

По greenfield-логике система должна быть универсальной, но первый concrete provider сейчас именно `Synxis`.

Поэтому нам нужны два слоя:

1. generic ingestion core
2. `Synxis`-specific profile

Без второго слоя система остаётся слишком абстрактной и непонятно:

- какие документы Synxis обязан дать
- как именно строится completeness check
- какие transport calls нужны
- какие filenames и document types считаются canonical
- какие provider-specific validation ошибки возможны уже на уровне bundle

## Источники для Synxis profile

### Из greenfield spec

В [`SYNXIS_RPAC_OTDS_GREENFIELD_SPEC.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/SYNXIS_RPAC_OTDS_GREENFIELD_SPEC.md:14) зафиксировано, что `Synxis Input Layer` должен:

- скачать полный bundle по одному отелю
- проверить наличие обязательных XML
- отдать bundle в нормализующий слой

Обязательные входные файлы:

- `Rates.xml`
- `Inventory.xml`
- `Availabilities.xml`
- `HotelDescriptiveInfo.xml`

### Из task backlog

В [`SYNXIS_RPAC_OTDS_TASKS.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/SYNXIS_RPAC_OTDS_TASKS.md:3482) `MVP Sprint 1` требует, чтобы система умела получить и провалидировать один bundle.

Это значит, что provider profile для Synxis нужен уже в первом спринте, иначе `FetchHotelBundle` и `Bundle Validation Service` останутся без concrete input rules.

### Из legacy PHP

Reference implementation:

- [DownloadPrices.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Command/Prices/DownloadPrices.php)
- [AbstractDownloadDeliveryCmd.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Framework/Application/Command/Prices/AbstractDownloadDeliveryCmd.php)

Из legacy видно:

- один bundle строится на один `hotelCode`
- APS transport даёт:
  - `Rates.xml`
  - `Inventory.xml`
  - `Availabilities.xml`
- Synxis descriptive client даёт:
  - `HotelDescriptiveInfo.xml`
- после скачивания 4 файлов bundle финализируется

## Synxis provider profile identity

```yaml
provider: synxis
profile: synxis_hotel_bundle_v1
source_system: synxis
bundle_scope: hotel
bundle_cardinality: one bundle per hotel_code
```

## Synxis required documents

### Canonical document set

```yaml
required_document_types:
  - rates
  - inventory
  - availabilities
  - hotel_descriptive_info
```

### Canonical filenames

```yaml
canonical_filenames:
  rates: Rates.xml
  inventory: Inventory.xml
  availabilities: Availabilities.xml
  hotel_descriptive_info: HotelDescriptiveInfo.xml
```

### Source by transport adapter

```yaml
transport_sources:
  rates:
    adapter: Synxis.Transport.APS.Client
    operation: getRates
  inventory:
    adapter: Synxis.Transport.APS.Client
    operation: getInventory
  availabilities:
    adapter: Synxis.Transport.APS.Client
    operation: getAvailabilities
  hotel_descriptive_info:
    adapter: Synxis.Transport.Descriptive.Client
    operation: getHotelDetails
```

## Synxis bundle completeness rule

Bundle считается complete только если:

1. присутствуют все 4 required documents
2. каждый required document non-empty
3. каждый document содержит syntactically valid XML
4. все 4 документа относятся к одному и тому же `hotel_code`

Если хотя бы одно условие нарушено, bundle не должен идти дальше в canonical layer.

## Synxis provider-specific validation rules

### P0 validation rules на уровне bundle

1. `Rates.xml` присутствует
2. `Inventory.xml` присутствует
3. `Availabilities.xml` присутствует
4. `HotelDescriptiveInfo.xml` присутствует
5. каждый файл не пустой
6. каждый файл парсится как XML
7. hotel identity согласована между всеми 4 документами

### P1 validation rules на уровне bundle

Эти проверки допустимо сделать как отдельный validation step сразу после completeness:

1. expected root element matches document type
2. XML namespace соответствует ожидаемому профилю
3. ответ не является transport-level fault payload
4. response envelope не пустой

## Synxis-specific reject taxonomy на bundle-level

Нужны machine-readable коды:

```yaml
bundle_errors:
  - synxis_missing_rates
  - synxis_missing_inventory
  - synxis_missing_availabilities
  - synxis_missing_hotel_descriptive_info
  - synxis_empty_rates
  - synxis_empty_inventory
  - synxis_empty_availabilities
  - synxis_empty_hotel_descriptive_info
  - synxis_invalid_rates_xml
  - synxis_invalid_inventory_xml
  - synxis_invalid_availabilities_xml
  - synxis_invalid_hotel_descriptive_info_xml
  - synxis_hotel_code_mismatch
  - synxis_transport_fault_payload
```

Важно:

- это не generic ошибки ingestion core
- это concrete bundle-profile ошибки именно для `synxis_hotel_bundle_v1`

## Synxis-specific metadata

Эти поля полезно сохранять в `metadata`:

```yaml
bundle_metadata:
  aps_request_ids: list<string>
  descriptive_request_ids: list<string>
  aps_endpoint: string | null
  descriptive_endpoint: string | null
  retry_count: integer
  legacy_delivery_reference: string | null
```

Для file-level metadata:

```yaml
file_metadata:
  request_operation: string
  transport_adapter: string
  source_endpoint: string | null
  request_reference: string | null
```

## Synxis -> Generic contract mapping

### Bundle-level mapping

| Synxis concept | Generic field |
|---|---|
| `synxis` provider | `provider` |
| `synxis_hotel_bundle_v1` | `profile` |
| hotel code from orchestration input | `hotel_code` |
| fetch moment | `collected_at` |
| aggregate checksum | `bundle_checksum` |

### File-level mapping

| Synxis file | `document_type` | `file_name` |
|---|---|---|
| Rates.xml | `rates` | `Rates.xml` |
| Inventory.xml | `inventory` | `Inventory.xml` |
| Availabilities.xml | `availabilities` | `Availabilities.xml` |
| HotelDescriptiveInfo.xml | `hotel_descriptive_info` | `HotelDescriptiveInfo.xml` |

## Synxis-specific lifecycle notes

Generic lifecycle остаётся общим, но для Synxis важно дополнительно зафиксировать:

- bundle не считается `collected`, пока не получены все 4 файла
- transport retry не должен порождать несколько bundle versions сам по себе
- provider fault payload должен переводить bundle в `invalid`, а не в `validated`

## Minimal valid Synxis bundle profile example

```yaml
provider: synxis
profile: synxis_hotel_bundle_v1
environment: prod
hotel_code: HTL123
required_documents:
  - Rates.xml
  - Inventory.xml
  - Availabilities.xml
  - HotelDescriptiveInfo.xml
status: collected
```

## Что это разблокирует в Sprint 1

После фиксации этого provider profile можно уже нормально делать:

1. `3.1` и `3.4`
   - auth builders знают, для каких transport operations они нужны
2. `3.2`, `3.3`, `3.5`, `3.6`
   - request builders и clients знают concrete document targets
3. `3.7`
   - `FetchHotelBundle` знает exact Synxis bundle recipe
4. `3.9`
   - validator знает expected document set и reject codes

## Правильная следующая граница

После этого уже можно проектировать:

- generic ingestion DB schema
- Synxis adapter modules
- Synxis bundle validator profile

Но нельзя ещё перескакивать сразу в `HotelData`, пока не зафиксированы:

- completeness rules
- lifecycle
- bundle-level reject taxonomy
