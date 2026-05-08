# Sprint 1 - Task 0.1

## Зафиксировать `ProviderHotelBundle`

### Правильная постановка задачи

В проекте механизм должен быть универсальным.

То есть мы строим не "систему для Synxis", а:

- общий ingestion/build pipeline
- общий bundle contract
- общий lifecycle / replay / versioning / storage model
- и отдельные provider adapters

`Synxis` в текущей документации и в текущем исследовании выступает как reference provider, на котором мы фиксируем первую реализацию и проверяем архитектуру.

Поэтому задача `0.1` должна быть прочитана в двух слоях:

1. generic layer: `ProviderHotelBundle`
2. provider profile layer: `SynxisHotelBundleProfile`

### Что такое `ProviderHotelBundle`

`ProviderHotelBundle` это immutable snapshot входных данных от внешнего provider по одному отелю и одной среде.

Bundle:

- принадлежит одному `provider`
- принадлежит одной `environment`
- принадлежит одному `hotel_code`
- содержит набор обязательных provider-specific документов
- хранит raw input snapshot
- валидируется до перехода в canonical layer
- после финализации не редактируется

### Почему это P0

Без этого контракта невозможно корректно определить:

- что ingestion layer вообще принимает на вход
- что должно храниться как snapshot
- как работает bundle validation
- как устроены replay и deduplication
- какие поля нужны в таблицах
- где заканчивается transport и начинается canonicalization

### Как читать Synxis в этой архитектуре

`Synxis` сейчас лишь даёт нам первый concrete bundle profile.

Для Synxis обязательный набор файлов такой:

- `Rates.xml`
- `Inventory.xml`
- `Availabilities.xml`
- `HotelDescriptiveInfo.xml`

Но для другого provider bundle profile может быть иным:

- другой набор документов
- другой transport
- другой способ вычисления completeness
- другой parser set

При этом:

- lifecycle bundle остаётся общим
- deduplication остаётся общей
- storage-модель остаётся общей
- replay/rebuild semantics остаётся общей

## Что видно из legacy PHP на примере Synxis

Из legacy PHP видно не универсальную модель, а provider-specific implementation, смешанную с delivery.

Изученные reference-файлы:

- [DownloadPrices.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Command/Prices/DownloadPrices.php)
- [AbstractDownloadDeliveryCmd.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Framework/Application/Command/Prices/AbstractDownloadDeliveryCmd.php)
- [AbstractPriceDelivery.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Framework/Delivery/AbstractPriceDelivery.php)
- [Zip.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Framework/Delivery/Archive/Zip.php)

Что они показывают:

- provider adapter скачивает provider-specific документы
- orchestration собирает bundle на один `hotelCode`
- retry logic и physical archive writing живут слишком близко к orchestration
- bundle в legacy фактически равен zip-архиву, а не доменной сущности

Это полезный reference, но не целевая модель для Elixir.

## Что нужно зафиксировать в задаче 0.1

### 1. Generic bundle contract

Нужно описать:

- идентичность bundle
- provider scope
- document set
- immutability
- lifecycle
- validation outcome
- replay semantics
- checksum / dedup rules

### 2. Generic role boundaries

Нужно развести ответственности:

- `Transport Adapter`
  - получает raw payload от конкретного provider
- `Bundle Assembler`
  - собирает один bundle на один hotel
- `Bundle Storage`
  - сохраняет immutable snapshot
- `Bundle Validator`
  - проверяет completeness и целостность
- `Canonical Layer`
  - читает уже валидный bundle

### 3. Provider profile contract

Для каждого provider отдельно нужно описывать:

- required document types
- canonical filenames
- completeness rules
- provider-specific transport metadata
- parser set

Для Synxis это просто первый profile.

## Что будет результатом

После закрытия `0.1` должно быть зафиксировано:

1. общий контракт `ProviderHotelBundle`
2. общие lifecycle и invariants
3. общая storage-логика
4. общие checksum/dedup rules
5. provider-specific profile для Synxis как reference implementation

## Что не входит в задачу 0.1

Не входит:

- реализация transport-клиентов
- реализация parser-ов
- реализация canonical model
- проектирование RPAC
- OTDS export

Задача `0.1` фиксирует только входной доменный контракт и границы слоя ingestion.

## Практический вывод

Правильная мысль для дальнейшей работы:

- не `SynxisHotelBundle` как центр всей системы
- а `ProviderHotelBundle` как generic core contract
- и `Synxis` как один из provider profiles поверх него
