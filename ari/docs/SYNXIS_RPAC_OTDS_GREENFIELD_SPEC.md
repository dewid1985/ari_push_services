# Greenfield Декомпозиция: `Synxis -> RPAC -> OTDS`

Если проект делается полностью с нуля, то `RPAC` нужно проектировать как отдельный доменный слой между `Synxis` и `OTDS`, а не как “ещё одну таблицу” или побочный результат importer-а.

Важно:

- текущая интеграция `Synxis` в этом документе используется как reference provider profile
- core ingestion/build/export механизм должен проектироваться как универсальный
- practical decomposition для `Sprint 1` вынесена в [`docs/Sprint1/INDEX_SPRINT1.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/INDEX_SPRINT1.md:1)

## Цель

Построить стабильный pipeline, который:

- принимает 4 SynXis XML по одному отелю
- нормализует их в `HotelData`
- строит `RPAC`
- преобразует `RPAC` в `OTDS XML`

## Архитектурные Слои

### 1. `Synxis Input Layer`

Задача слоя:

- скачать и собрать полный bundle по одному отелю
- проверить, что все обязательные XML присутствуют
- отдать bundle в нормализующий слой

Обязательные входные файлы:

- `Rates.xml`
- `Inventory.xml`
- `Availabilities.xml`
- `HotelDescriptiveInfo.xml`

Выход слоя:

- `SynxisHotelBundle`

### Подробная Декомпозиция `Synxis Input Layer`

Этот слой в текущем PHP-проекте фактически состоит из трёх подслоёв:

1. orchestration layer
2. transport clients layer
3. delivery/bundling layer

При переносе в `Elixir/Phoenix` их нужно разносить по отдельным модулям и не смешивать.

### 1.1. Orchestration Layer

Задача:

- определить список отелей для загрузки
- вызвать загрузку 4 обязательных XML по одному отелю
- сложить их в один bundle
- завершить сборку архива

Текущий основной orchestration-файл:

- [DownloadPrices.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Command/Prices/DownloadPrices.php)

Логика файла:

- получает список hotel codes через framework import flow
- создаёт два клиента:
  - `APSClient` для `Rates.xml`, `Inventory.xml`, `Availabilities.xml`
  - `SynxisClient` для `HotelDescriptiveInfo.xml`
- для каждого отеля вызывает `fetchHotelData(hotelCode, apsClient, synxisClient)`
- внутри `fetchHotelData` последовательно добавляет в bundle:
  - `Rates.xml`
  - `Inventory.xml`
  - `Availabilities.xml`
  - `HotelDescriptiveInfo.xml`
- после записи всех файлов вызывает `finalizeHotelArchive(hotelCode)`

Что нужно вынести в Elixir:

- `Synxis.Input.FetchHotelBundle`
- `Synxis.Input.FetchHotelBundle.run(hotel_code)`
- orchestration не должен знать детали SOAP/XML serialization
- orchestration должен работать только с абстракциями:
  - `fetch_rates/1`
  - `fetch_inventory/1`
  - `fetch_availabilities/1`
  - `fetch_descriptive_info/1`
  - `store_bundle/2`

### 1.2. APS Transport Layer

Задача:

- сходить в private APS service
- получить сырые XML response
- отдать XML orchestration-слою

Текущие файлы:

- [APSClient.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/APSClient.php)
- [APSClientFactory.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/APSClientFactory.php)
- [GetRatesRequest.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/Requests/GetRatesRequest.php)
- [GetInventoriesRequest.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/Requests/GetInventoriesRequest.php)
- [GetAvailabilitiesRequest.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/Requests/GetAvailabilitiesRequest.php)
- [PayloadRequest.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/Requests/Struct/PayloadRequest.php)
- [Header.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/Requests/Headers/Header.php)
- [Security.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/Requests/Headers/Security.php)
- [UsernameToken.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/APSClient/Requests/Headers/UsernameToken.php)

Логика по файлам:

`APSClient.php`

- инициализирует SOAP client
- валидирует наличие:
  - wsdl
  - url
  - username
  - password
  - timeout
- настраивает SSL context и timeout
- ставит WS-Security header
- предоставляет 3 transport-операции:
  - `getRates(hotelCode)`
  - `getInventory(hotelCode)`
  - `getAvailabilities(hotelCode)`
- возвращает именно raw SOAP response XML через `__getLastResponse()`
- превращает SOAP faults в domain exception `APSClientException`

`APSClientFactory.php`

- собирает `APSClient` из config
- прокидывает:
  - wsdl path
  - private url
  - private username
  - private password
  - timeout

`GetRatesRequest.php`, `GetInventoriesRequest.php`, `GetAvailabilitiesRequest.php`

- это thin wrappers над `PayloadRequest`
- бизнес-логики почти нет
- нужны только как отдельные request envelope types

`PayloadRequest.php`

- кладёт `HotelCode` в SOAP payload
- содержит также поля `CustomerCode` и `DeliveryDate`, но в текущем flow они фактически не используются

`Header.php`, `Security.php`, `UsernameToken.php`

- отвечают только за WS-Security envelope
- бизнес-логики импорта здесь нет

Что нужно вынести в Elixir:

- `Synxis.Transport.APS.Client`
- `Synxis.Transport.APS.Requests.GetRates`
- `Synxis.Transport.APS.Requests.GetInventory`
- `Synxis.Transport.APS.Requests.GetAvailabilities`
- `Synxis.Transport.APS.Auth`

Требования к Elixir-реализации:

- transport layer должен возвращать raw XML
- transport layer не должен писать в bundle storage
- transport layer не должен решать, какие файлы обязательны
- transport layer не должен знать про `HotelData` и `RPAC`

### 1.3. SynXis Descriptive SOAP Layer

Задача:

- сходить в HTNG/OTA descriptive endpoint
- получить `HotelDescriptiveInfo.xml`
- вернуть raw XML orchestration-слою

Текущие файлы:

- [SynxisClient.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/SynxisClient.php)
- [Credential.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Common/Credential.php)
- [HTNGHeader.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Common/HTNGHeader.php)
- [From.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Common/From.php)
- [HotelDescriptiveInfoRQ.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/HotelDescriptiveInfoRQ.php)
- [HotelDescriptiveInfo.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/HotelDescriptiveInfo.php)
- [HotelInfo.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/HotelInfo.php)
- [FacilityInfo.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/FacilityInfo.php)
- [Policies.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/Policies.php)
- [AreaInfo.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/AreaInfo.php)
- [AffiliationInfo.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/AffiliationInfo.php)
- [POS.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/POS.php)
- [Source.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/Source.php)
- [RequestorID.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/RequestorID.php)
- [CompanyName.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Requests/Types/CompanyName.php)
- [HotelDescriptiveInfoRS.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Client/Responses/HotelDescriptiveInfoRS.php)

Логика по файлам:

`SynxisClient.php`

- инициализирует SOAP client для descriptive endpoint
- настраивает headers формата HTNG
- строит `OTA_HotelDescriptiveInfoRQ`
- вызывает `GetHotelDetails`
- сохраняет:
  - `lastRequest`
  - `lastResponse`
- в orchestration flow raw XML достаётся именно через `lastResponse`
- SOAP fault переводится в `SynxisClientException`

`Credential.php`, `HTNGHeader.php`, `From.php`

- инфраструктурные объекты для auth/header assembly

`HotelDescriptiveInfoRQ.php` и связанные request types

- описывают, какие sections descriptive response запрашиваются
- именно здесь задаётся состав descriptive payload:
  - hotel info
  - facility info
  - policies
  - area info
  - affiliation info

Что нужно вынести в Elixir:

- `Synxis.Transport.Descriptive.Client`
- `Synxis.Transport.Descriptive.RequestBuilder`
- `Synxis.Transport.Descriptive.Auth`

Требования к Elixir-реализации:

- descriptive client должен возвращать raw XML
- descriptive client не должен ничего знать про archive/bundle
- request builder должен быть изолирован от orchestration

### 1.4. Delivery и Bundling Layer

Задача:

- собрать 4 XML в один physical bundle
- гарантировать повторяемую структуру bundle
- отдать bundle downstream-слою

Текущие файлы:

- [AbstractDownloadDeliveryCmd.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Framework/Application/Command/Prices/AbstractDownloadDeliveryCmd.php)
- [AbstractPriceDelivery.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Framework/Delivery/AbstractPriceDelivery.php)
- [Zip.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Framework/Delivery/Archive/Zip.php)
- [SynxisPricesDelivery.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/SynxisPricesDelivery.php)

Логика по файлам:

`AbstractDownloadDeliveryCmd.php`

- создаёт delivery context
- даёт orchestration API:
  - `addHotelFile(hotelId, fileName, providerFn, subDir)`
  - `finalizeHotelArchive(hotelId)`
- реализует retry policy:
  - до 3 попыток на каждый файл
- пишет каждый файл в zip under contract directory
- финализирует временный hotel archive в итоговый zip

`AbstractPriceDelivery.php`

- умеет выбрать hotel archive по `hotelCode`
- умеет создать tmp hotel archive
- умеет финализировать tmp archive в постоянный
- умеет проверить `hasHotel(hotelCode)`

`Zip.php`

- физически пишет файлы в zip archive
- хранит структуру архива
- читает файл по path внутри архива
- именно этот класс задаёт текущую archive semantics

`SynxisPricesDelivery.php`

- provider-specific subclass без собственной логики
- маркирует, что для SynXis используется стандартный price delivery flow

Текущее фактическое устройство bundle:

- один zip на один hotel
- внутри zip файлы кладутся в subdir `default`
- downstream ожидает:
  - `default/Rates.xml`
  - `default/Inventory.xml`
  - `default/Availabilities.xml`
  - `default/HotelDescriptiveInfo.xml`

Это видно downstream в:

- [HotelDataFactory.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/HotelData/HotelDataFactory.php)

Что нужно вынести в Elixir:

- `Synxis.Input.BundleStore`
- `Synxis.Input.BundleWriter`
- `Synxis.Input.BundleReader`
- `Synxis.Input.BundleValidator`

Рекомендация для Phoenix:

- не тащить zip-логику в transport clients
- bundling сделать отдельным persistence/service слоем
- отдельно описать contract:
  - обязательные имена файлов
  - обязательная директория
  - правила финализации bundle

### 1.5. Config и Dependency Wiring

Задача:

- собрать credentials
- собрать endpoints
- собрать timeout policy
- подать зависимости в orchestration и clients

Текущие файлы:

- [Config.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Config.php)
- [ContainerFactory.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/ContainerFactory.php)

Логика по файлам:

`Config.php`

- описывает обязательные provider parameters
- разделяет:
  - `SERVICE.*` для descriptive SOAP
  - `ARI_PUSH_SERVICE.*` для APS
- содержит:
  - wsdl contract
  - wsdl location
  - usernames/passwords
  - channel id
  - code
  - id context
  - timeout

`ContainerFactory.php`

- связывает config с runtime services
- создаёт:
  - `SynxisClient`
  - `APSClient`
  - `SynxisPricesDelivery`
  - `SynxisMasterData`

Что нужно вынести в Elixir:

- `Synxis.Config`
- `Synxis.Transport.APS.ClientConfig`
- `Synxis.Transport.Descriptive.ClientConfig`
- `Synxis.Input.Supervisor`

### 1.6. Input Validation Contract

В greenfield-архитектуре этот слой должен иметь отдельный validator, которого сейчас явно нет как самостоятельного объекта.

Нужно валидировать:

- что все 4 файла существуют
- что каждый файл не пустой
- что каждый XML парсится
- что descriptive XML относится к тому же `hotel_code`
- что bundle не финализируется частично как “успешный”

Минимальный результат валидации:

- `valid`
- `invalid_missing_file`
- `invalid_empty_file`
- `invalid_xml`
- `invalid_hotel_mismatch`

### 1.7. Рекомендуемая Декомпозиция Для Elixir/Phoenix

Минимальный набор модулей:

- `Synxis.Input.FetchHotelBundle`
- `Synxis.Input.Bundle`
- `Synxis.Input.BundleStore`
- `Synxis.Input.BundleValidator`
- `Synxis.Transport.APS.Client`
- `Synxis.Transport.APS.RequestBuilder`
- `Synxis.Transport.Descriptive.Client`
- `Synxis.Transport.Descriptive.RequestBuilder`
- `Synxis.Config`

Минимальный flow:

1. orchestrator получает `hotel_code`
2. APS client скачивает `Rates.xml`
3. APS client скачивает `Inventory.xml`
4. APS client скачивает `Availabilities.xml`
5. descriptive client скачивает `HotelDescriptiveInfo.xml`
6. bundle writer собирает `SynxisHotelBundle`
7. bundle validator валидирует bundle
8. валидный bundle передаётся в `HotelDataFactory`

### 1.8. Новые Задачи Для Переписывания Input Layer

#### Задача IL.1. Выделить orchestration contract для загрузки bundle

Нужно зафиксировать:

- вход: `hotel_code`
- выход: `SynxisHotelBundle`
- список обязательных transport calls
- правила retry
- правила fail-fast

#### Задача IL.2. Выделить APS transport contract

Нужно зафиксировать:

- как строятся запросы
- какие endpoint/config values обязательны
- какой raw XML возвращается
- какие ошибки считаются transport errors

#### Задача IL.3. Выделить descriptive SOAP transport contract

Нужно зафиксировать:

- как строится `HotelDescriptiveInfoRQ`
- какие sections обязательны
- как возвращается raw XML
- какие ошибки считаются fatal

#### Задача IL.4. Выделить bundle storage contract

Нужно зафиксировать:

- формат bundle
- именование файлов
- политику временного хранения
- политику финализации

#### Задача IL.5. Выделить input validation contract

Нужно зафиксировать:

- какие проверки обязательны
- какие reject reasons возможны
- когда bundle считается непригодным

### 2. `Canonical Layer`

Задача слоя:

- разобрать bundle
- собрать каноническую модель отеля
- убрать зависимость build-логики от сырого XML

Выход слоя:

- `HotelData`

### Подробная Декомпозиция `Canonical Layer`

Этот слой в текущем PHP-коде уже существует, но в сильно смешанном виде:

- он читает bundle
- он создаёт DOM/XPath представления XML
- он уже подтягивает business mappings
- в него уже протекла часть build-логики

При переносе в `Elixir/Phoenix` этот слой нужно сделать отдельным и жёстко изолированным от `RPAC Build Layer`.

### 2.1. Текущая Точка Входа Canonical Layer

Главный входной файл:

- [HotelDataFactory.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/HotelData/HotelDataFactory.php)

Логика файла:

- проверяет, что delivery содержит hotel archive
- открывает hotel bundle через price delivery
- читает из архива 4 обязательных XML:
  - `default/Inventory.xml`
  - `default/Rates.xml`
  - `default/Availabilities.xml`
  - `default/HotelDescriptiveInfo.xml`
- для каждого XML:
  - достаёт raw content
  - парсит его в `DOMDocument`
  - строит `DOMXPath`
- создаёт объект `HotelData`
- дополнительно инжектит:
  - `ContractDataProvider`
  - `FilterService`

Проблема текущей реализации:

- factory не только создаёт canonical model, но и сразу подмешивает зависимости build-слоя
- canonical layer от этого перестаёт быть “чистой нормализацией”

Что нужно вынести в Elixir:

- `Synxis.Canonical.HotelDataFactory`
- `Synxis.Canonical.BundleParser`
- `Synxis.Canonical.XmlDocument`

Требование:

- factory должен создавать только canonical model
- factory не должен инжектить RPAC-specific services

### 2.2. Текущая Canonical Model

Главный canonical-файл:

- [HotelData.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/HotelData/HotelData.php)

Что сейчас делает `HotelData`:

- хранит `hotelCode`
- хранит 4 XML-документа в виде `DOMXPath`
- регистрирует OTA namespace
- поднимает mapping `ratePlan -> board`
- отдаёт набор методов, на которых живёт downstream build:
  - `getRateCodesToProcess()`
  - `getBoardCodeForRatePlan(ratePlan)`
  - `getRoomsCodesForRatePlan(ratePlan)`
  - `getMaxChildAgeDescriptive()`
  - `getCurrencyForRatePlan(ratePlan)`
  - `getRoomsTypes()`
  - `getBoardsTypes()`

Проблема текущей реализации:

- canonical model хранит не нормализованные данные, а `DOMXPath`
- downstream зависит от XML query semantics напрямую
- canonical model знает про `FilterService`
- canonical model знает про `ContractDataProvider`
- это уже не pure domain object, а смесь:
  - parsed XML
  - mapping service
  - build helper

Что нужно сделать в Elixir:

`HotelData` должен стать чистой структурой данных, например:

- `hotel_code`
- `rate_plans`
- `boards`
- `rooms`
- `currency`
- `child_policy`
- `occupancy_constraints`
- `descriptive_rooms`

То есть downstream build не должен читать XPath из `HotelData`.

### 2.3. Bundle Parsing Подслой

Сейчас parsing bundle размазан по:

- [HotelDataFactory.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/HotelData/HotelDataFactory.php)

Что именно делает parsing-подслой:

- берёт zip archive
- извлекает XML-файл по path
- парсит XML
- создаёт DOM/XPath
- регистрирует namespace `ota`

Это нужно вынести в отдельный слой:

- `Synxis.Canonical.BundleReader`
- `Synxis.Canonical.XmlParser`
- `Synxis.Canonical.NamespaceRegistry`

Требования к Elixir-реализации:

- parser должен принимать raw XML
- parser должен возвращать либо parsed document, либо canonical parse error
- parser не должен знать про rate plan, board, RPAC

### 2.4. RatePlan-to-Board Mapping Подслой

Сейчас этот кусок живёт в:

- [ContractDataProvider.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/ContractDataProvider.php)

Логика файла:

- получает provider environment
- маппит его в SynXis environment code
- читает из contract details mapping:
  - `rate_code -> meal_plan`
- отдаёт:
  - importable rates
  - boards for hotel

Фактически это не transport-логика и не RPAC-логика.
Это часть canonical enrichment.

Что нужно вынести в Elixir:

- `Synxis.Canonical.RatePlanBoardMappingProvider`

Требования:

- canonical layer должен обогащать `HotelData` уже resolved mapping-ом
- downstream layer не должен сам ходить в mapping storage

### 2.5. Child/Adult Semantics Подслой

Сейчас эта логика сидит внутри:

- [HotelData.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/HotelData/HotelData.php)

Текущая логика:

- читает `MaxChildAge` из descriptive policies
- если `MaxChildAge` не найден:
  - проверяет признак adult-only hotel через service code
  - если это adult-only hotel, принимает `17` как max child age
- кеширует вычисленный результат

Почему это важно:

- это уже чистая canonical business semantics
- она не должна жить в build processor

Что нужно вынести в Elixir:

- `Synxis.Canonical.ChildPolicyResolver`

Выход этого подслоя:

- `max_child_age`
- `min_adult_age`
- `child_policy_resolution_status`

### 2.6. Room Extraction Подслой

Сейчас room extraction сидит внутри:

- [HotelData.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/HotelData/HotelData.php)

Текущая логика:

- по каждому `ratePlanCode` выбирает `RatePlan`
- внутри него собирает `InvTypeCode`
- возвращает уникальные room codes

Проблема:

- это extraction rule, а не метод низкоуровневой модели
- при смене XML-формата будет трудно тестировать изолированно

Что нужно вынести в Elixir:

- `Synxis.Canonical.RoomExtractor`

Выход:

- rooms per rate plan
- unique hotel rooms set

### 2.7. Board Extraction Подслой

Сейчас boards фактически приходят не из XML, а из mapping storage через:

- [ContractDataProvider.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/ContractDataProvider.php)

Это важный architectural decision:

- для `Synxis` board не должен вычисляться “на лету” из ценового XML
- board для canonical model должен приходить как resolved mapping `rate plan -> meal plan`

Что нужно вынести в Elixir:

- `Synxis.Canonical.BoardResolver`

Выход:

- board per rate plan
- unique hotel boards set

### 2.8. Currency Extraction Подслой

Сейчас currency extraction сидит внутри:

- [HotelData.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/HotelData/HotelData.php)

Текущая логика:

- берёт `CurrencyCode` из rate plan XML

Проблема:

- это ещё один extraction rule, который смешан с общей моделью

Что нужно вынести в Elixir:

- `Synxis.Canonical.CurrencyExtractor`

Выход:

- currency per rate plan
- hotel-level currency policy

### 2.9. Descriptive Room Whitelist Подслой

Сейчас сама whitelist-логика используется downstream в build-слое, но canonical источник этих данных находится в descriptive XML.

С Canonical Layer точки зрения нужно уже на этом этапе подготовить:

- список descriptive room codes
- признаки inconsistent room references

Сейчас raw source для этого живёт в:

- [HotelData.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/HotelData/HotelData.php)

Что нужно вынести в Elixir:

- `Synxis.Canonical.DescriptiveRoomExtractor`

Выход:

- `descriptive_room_codes`
- `descriptive_room_index`

### 2.10. Occupancy Constraints Подслой

Сейчас тут есть важная архитектурная проблема.

В canonical model уже протащен:

- [FilterService.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/OccupancyFilter/FilterService.php)
- [FilterServiceFactory.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/OccupancyFilter/FilterServiceFactory.php)
- [BlanksProvider.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/OccupancyFilter/BlanksProvider.php)

Что они делают:

- берут occupancy blanks из `roomtypes_matching.synxis_allowed_occ`
- по `roomCode-hotelCode` подтягивают допустимые взрослые/детские конфигурации
- потом уже в build-слое навешивают RPAC filters

Почему это проблема:

- canonical layer не должен хранить `RPAC` condition builder
- но canonical layer должен знать фактические occupancy constraints

Правильное разделение:

- canonical layer:
  - извлекает occupancy constraints как данные
- build layer:
  - превращает их в RPAC filters

Что нужно вынести в Elixir:

- `Synxis.Canonical.OccupancyConstraintProvider`

Выход:

- `allowed_occupancies`
- `occupancy_override_enabled`
- `occupancy_constraint_source`

### 2.11. Где Сейчас Слой Загрязнён

На текущем PHP-состоянии Canonical Layer загрязнён следующими вещами:

1. он хранит `DOMXPath`, а не canonical data
2. он тянет build-specific occupancy filter service
3. он опирается на storage mappings прямо во время model construction
4. он отдаёт helper methods вместо явной нормализованной структуры

Это значит, что при переносе на `Elixir/Phoenix` нельзя переписывать его “как есть”.
Его нужно сначала логически распаковать.

### 2.12. Как Должен Выглядеть `HotelData` В Elixir

Рекомендуемая структура:

- `hotel_code`
- `provider`
- `environment`
- `rate_plans`
- `rooms`
- `boards`
- `descriptive_rooms`
- `currency`
- `child_policy`
- `occupancy_constraints`
- `mapping_metadata`

Где:

`rate_plans`

- code
- board_code
- currency
- room_codes

`rooms`

- provider_room_code
- descriptive_present
- occupancy_meta

`boards`

- provider_board_code
- source_rate_plans

`child_policy`

- max_child_age
- min_adult_age
- resolution_source

`occupancy_constraints`

- room_code
- allowed_occupancies
- override_enabled

### 2.13. Рекомендуемая Декомпозиция Для Elixir/Phoenix

Минимальный набор модулей:

- `Synxis.Canonical.HotelDataFactory`
- `Synxis.Canonical.BundleReader`
- `Synxis.Canonical.XmlParser`
- `Synxis.Canonical.RoomExtractor`
- `Synxis.Canonical.BoardResolver`
- `Synxis.Canonical.CurrencyExtractor`
- `Synxis.Canonical.ChildPolicyResolver`
- `Synxis.Canonical.DescriptiveRoomExtractor`
- `Synxis.Canonical.OccupancyConstraintProvider`
- `Synxis.Canonical.RatePlanBoardMappingProvider`

Минимальный flow:

1. factory получает `SynxisHotelBundle`
2. bundle reader читает 4 XML
3. xml parser строит внутренние parsed documents
4. room extractor извлекает rooms
5. board resolver резолвит boards
6. currency extractor резолвит currency
7. child policy resolver строит age semantics
8. descriptive room extractor строит whitelist room list
9. occupancy provider подтягивает occupancy constraints
10. factory собирает чистый `HotelData`

### 2.14. Новые Задачи Для Переписывания Canonical Layer

#### Задача CL.1. Выделить canonical factory contract

Нужно зафиксировать:

- вход: `SynxisHotelBundle`
- выход: `HotelData`
- список обязательных extraction steps
- список reject reasons

#### Задача CL.2. Выделить XML parsing contract

Нужно зафиксировать:

- как читаются 4 XML
- какие namespace обязательны
- какие parse errors считаются fatal

#### Задача CL.3. Выделить room extraction contract

Нужно зафиксировать:

- как rooms извлекаются из rate plans
- как определяется unique room set
- как room связывается с descriptive data

#### Задача CL.4. Выделить board resolution contract

Нужно зафиксировать:

- как `rate plan` связывается с `board`
- что делать при отсутствии mapping
- где проходит граница между canonical layer и mapping storage

#### Задача CL.5. Выделить child/adult semantics contract

Нужно зафиксировать:

- как определяется `max_child_age`
- как определяется `min_adult_age`
- что считать unresolved child policy

#### Задача CL.6. Выделить occupancy constraints contract

Нужно зафиксировать:

- какие occupancy данные приходят из external storage
- как они привязываются к room
- что является canonical constraint, а что уже RPAC filter

### 3. `RPAC Build Layer`

Задача слоя:

- преобразовать `HotelData` в нормализованный `RPAC`
- построить offers, intersections, prices, availabilities, filters

Выход слоя:

- `RPAC`

### Подробная Декомпозиция `RPAC Build Layer`

Этот слой в текущем PHP-проекте уже существует, но он собран вокруг XML-aware helper-объектов и тесно связан с текущей реализацией `HotelData`.

При переносе в `Elixir/Phoenix` его нужно переписывать не как набор “процессоров поверх XPath”, а как отдельный deterministic pipeline:

- `HotelData -> Offers -> Intersections -> Prices/Availabilities/Filters -> RPAC`

### 3.1. Текущая Точка Входа Build Layer

Главный build-файл:

- [RpacBuilder.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/RpacBuilder.php)

Где он вызывается сейчас:

- [HotelImporter.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Command/Prices/Importer/HotelImporter.php)

Текущий вход в build layer:

- `HotelData`
- `importFilter(room, board)`

Текущий выход:

- `RpacCollection`

Логика верхнего уровня:

- берёт `ratePlanCode` из `HotelData`
- для каждого rate plan строит отдельный offer
- внутри offer строит набор intersections
- на каждую intersection навешивает:
  - occupancies
  - availability
  - restrictions
  - prices
  - filters
- после этого компилирует всё в `RpacCollection`

Что нужно вынести в Elixir:

- `Synxis.RPAC.BuildService`
- `Synxis.RPAC.OfferBuilder`
- `Synxis.RPAC.IntersectionBuilder`

### 3.2. Offer Build Orchestration

Текущая orchestration-логика живёт в:

- [RpacBuilder.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/RpacBuilder.php)

Что она делает:

- `buildCollection/2`
  - превращает набор offers в `RpacCollection`
- `buildOffers/2`
  - итерирует по всем `ratePlanCode`
- `buildRpacForRatePlan/3`
  - создаёт `OfferCompiler`
  - находит `boardCode` для rate plan
  - получает список комнат
  - фильтрует их через matching/filter callback
  - проверяет descriptive room whitelist
  - строит intersections
  - применяет room suffix
  - компилирует один offer

Проблема текущей реализации:

- orchestration напрямую знает о descriptive room consistency
- orchestration напрямую знает о suffix policy
- orchestration напрямую знает об event dispatch side effects

При переносе в Elixir это нужно разнести:

- orchestration only
- validation/reject handling
- identity policy

### 3.3. Matching и Import Filter Dependency

Build layer сейчас зависит от callback, который создаётся в:

- [HotelImporter.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Command/Prices/Importer/HotelImporter.php)

Текущая логика callback:

- `isValidBoard(board)`
- `isValidRoom(room-hotel)`
- `checkFilter(room, board)`

Это важно, потому что build layer фактически не автономен.
Он зависит от внешнего решения:

- какие boards разрешены
- какие rooms разрешены
- какие room/board combinations отфильтрованы

В greenfield-архитектуре это нужно оформить как отдельный контракт:

- `BuildEligibilityPolicy`

Что нужно вынести в Elixir:

- `Synxis.RPAC.BuildEligibilityPolicy`

Вход:

- `room_code`
- `board_code`
- `hotel_code`

Выход:

- `allow`
- `reject_room_unmapped`
- `reject_board_unmapped`
- `reject_combination_filtered`

### 3.4. Descriptive Room Whitelist и Inconsistent Rooms

Текущая логика живёт в:

- [RpacBuilder.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/RpacBuilder.php)

Что происходит:

- builder берёт список room codes из rates
- builder отдельно читает список `GuestRoom/@Code` из descriptive XML
- если room из rate plan отсутствует в descriptive data:
  - intersection не строится
  - создаётся warning event

Связанный event:

- [InconsistentRoomsDelivered.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Events/InconsistentRoomsDelivered.php)

Это отдельная build policy и её нужно выделить:

- `DescriptiveConsistencyPolicy`

Что нужно вынести в Elixir:

- `Synxis.RPAC.DescriptiveConsistencyPolicy`

Вход:

- `rooms_from_rates`
- `rooms_from_descriptive`

Выход:

- `consistent_rooms`
- `inconsistent_rooms`
- `reject_reason` или `warning_reason`

### 3.5. Intersection Builder

Текущая intersection-логика живёт в:

- [RpacBuilder.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/RpacBuilder.php)

Что делает `processIntersection(...)`:

- вычисляет `minAdultAge`
- строит base occupancy
- проверяет occupancy override
- создаёт intersection через compiler
- добавляет occupancy filters
- задаёт description
- задаёт `minAdultAge`
- добавляет обязательный filter “минимум 1 adult”
- запускает processors:
  - inventories
  - availabilities
  - rates

Что нужно вынести в Elixir:

- `Synxis.RPAC.IntersectionBuilder`

Вход:

- room
- board
- rate plan
- `HotelData`

Выход:

- `RpacIntersectionDraft`

### 3.6. Occupancy Builder

Сейчас occupancy builder встроен в:

- [RpacBuilder.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/RpacBuilder.php)

Текущая логика:

- ищет room в descriptive XML
- читает:
  - `MaxOccupancy`
  - `MaxRollaways`
- вычисляет `maxPax = MaxOccupancy + MaxRollaways`
- строит occupancy вида:
  - минимум 1 traveller
  - максимум `maxPax`

Проблема:

- occupancy extraction и occupancy-to-RPAC mapping смешаны

Нужно разделить:

- canonical occupancy facts
- RPAC occupancy construction

Что нужно вынести в Elixir:

- `Synxis.RPAC.OccupancyBuilder`

Выход:

- `occupancy_rules`
- `min_adult_age`
- `max_pax`

### 3.7. Occupancy Override и XRes Filters

Сейчас build layer опирается на occupancy override service:

- [FilterService.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/OccupancyFilter/FilterService.php)

Что происходит:

- если override включён и для room ничего не разрешено:
  - intersection вообще не создаётся
- если override включён и blank list есть:
  - builder добавляет RPAC filters в intersection

Проблема:

- build layer одновременно решает:
  - строить ли intersection
  - какие occupancy filters применить

Это нужно оформить отдельным policy слоем:

- `OccupancyOverridePolicy`

Что нужно вынести в Elixir:

- `Synxis.RPAC.OccupancyOverridePolicy`

Вход:

- room
- canonical occupancy constraints
- min adult age

Выход:

- `skip_intersection`
- `apply_filters`
- `no_override`

### 3.8. Inventories Processor

Текущий файл:

- [InventoriesProcessor.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/InventoriesProcessor.php)

Что делает:

- читает inventory notifications
- выбирает только те notifications, которые относятся к room/hotel
- сортирует notifications по `TimeStamp`
- newer notification имеет приоритет над older
- определяет, какие даты покрываются какой notification
- для каждой даты определяет availability status:
  - `OPEN`
  - `CLOSED`
- записывает day-level availability в intersection

Это важная бизнес-логика:

- inventories у SynXis не просто “таблица статусов”
- это журнал уведомлений с приоритетом по времени

Что нужно вынести в Elixir:

- `Synxis.RPAC.InventoryReducer`

Вход:

- room
- hotel
- inventory notifications

Выход:

- reduced inventory timeline

### 3.9. Availabilities Processor

Текущий файл:

- [AvailabilitiesProcessor.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/AvailabilitiesProcessor.php)

Что делает:

- получает релевантные availability notifications для:
  - hotel
  - room
  - rate plan
- сортирует notifications по времени
- выделяет даты, которые покрывает каждый notification
- мержит даты в периоды
- применяет business restrictions:
  - master open/close
  - arrival open/close
  - departure open/close
  - LOS restrictions
- превращает часть ограничений в RPAC filters
- превращает часть ограничений в RPAC availabilities

Особенность:

- этот processor смешивает:
  - availability state
  - booking restrictions
  - LOS semantics

Что нужно вынести в Elixir:

- `Synxis.RPAC.AvailabilityReducer`
- `Synxis.RPAC.RestrictionMapper`
- `Synxis.RPAC.LengthOfStayMapper`

### 3.10. Booking Offsets Helper

Текущий файл:

- [BookingOffsetsHelper.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/BookingOffsetsHelper.php)

Что делает:

- ищет `MinAdvancedBookingOffset` / `MaxAdvancedBookingOffset`
- читает соответствующие notifications
- раскладывает offsets по датам
- строит booking-date filters
- добавляет их в intersection

Это отдельный подслой и он не должен быть hidden helper inside availability logic.

Что нужно вынести в Elixir:

- `Synxis.RPAC.BookingOffsetReducer`

Выход:

- booking offset restrictions per date/period

### 3.11. Rates Processor

Текущий файл:

- [RatesProcessor.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/RatesProcessor.php)

Что делает:

- для каждого `RatePlan`
  - определяет `minAdultAge`
  - добавляет traveller filters
  - добавляет prices
- читает `BaseByGuestAmt`
- строит age-aware pricing
- строит layered price resolution
- использует `TimeStamp` как price weight
- различает adult/child pricing semantics
- строит pax-sensitive RPAC prices

Этот processor решает сразу несколько задач:

- age semantics resolution
- filter construction
- price construction
- price precedence resolution

Правильнее разделить:

- `MinAdultAgeResolver`
- `TravellerConstraintBuilder`
- `PriceBuilder`
- `PricePrecedencePolicy`

Что нужно вынести в Elixir:

- `Synxis.RPAC.MinAdultAgeResolver`
- `Synxis.RPAC.TravellerConstraintBuilder`
- `Synxis.RPAC.PriceBuilder`
- `Synxis.RPAC.PricePriorityResolver`

### 3.12. Room Suffix Policy

Текущая логика живёт в:

- [RpacBuilder.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Rpac/RpacBuilder.php)

Что происходит:

- после того как intersections собраны,
  builder вручную меняет `roomCode`
  на `roomCode-hotelCode`

Это критически важная identity policy.

Проблема:

- suffixing происходит поздно и скрыто
- это side effect mutation уже собранной intersection

В greenfield-архитектуре нужно вынести это в отдельный policy:

- `RoomIdentityPolicy`

Что нужно вынести в Elixir:

- `Synxis.RPAC.RoomIdentityPolicy`

Вход:

- room_code
- hotel_code

Выход:

- canonical_room_code

### 3.13. Offer Compilation

Текущий flow в конце builder:

- собирает все intersections в `OfferCompiler`
- компилирует один offer с currency
- потом агрегирует offers в `RpacCollection`

Это отдельный выходной build contract:

- build layer должен вернуть не “промежуточные куски XML logic”, а deterministic RPAC model

Что нужно вынести в Elixir:

- `Synxis.RPAC.OfferCompiler`
- `Synxis.RPAC.CollectionCompiler`

### 3.14. Reject Points и Build Events

Текущие reject/warning события:

- [AdultAgeWasNotResolved.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Events/AdultAgeWasNotResolved.php)
- [InconsistentRoomsDelivered.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Events/InconsistentRoomsDelivered.php)
- [MinChildAgeIsNotDefined.php](/home/d.shein/Projects/xres_git/modules/xhotels/classes/Provider/Synxis/Events/MinChildAgeIsNotDefined.php)

Build layer должен явно поддерживать следующие reject/warn точки:

- room отсутствует в descriptive data
- child/adult semantics не разрешились
- occupancy override вырезал intersection
- inventory/availability/rates processor не смогли построить результат
- rate plan не дал ни одной валидной intersection

Что нужно вынести в Elixir:

- `Synxis.RPAC.BuildReject`
- `Synxis.RPAC.BuildWarning`

### 3.15. Где Сейчас Слой Загрязнён

На текущем PHP-состоянии build layer загрязнён следующими вещами:

1. он опирается на `DOMXPath` через `HotelData`
2. он зависит от внешнего import filter callback
3. он мутирует identity поздно через suffix side effect
4. он смешивает:
   - orchestration
   - validation
   - reduction
   - pricing
   - availability mapping
5. он пишет event side effects прямо по ходу сборки

Значит при переносе на `Elixir/Phoenix` слой надо сначала логически распаковать.

### 3.16. Как Должен Выглядеть Build Contract В Elixir

Рекомендуемый контракт:

Вход:

- `HotelData`
- `BuildEligibilityPolicy`
- `RoomIdentityPolicy`
- `OccupancyOverridePolicy`

Выход:

- `RpacBuildResult`

Где `RpacBuildResult` содержит:

- `offers`
- `warnings`
- `rejects`
- `stats`

`offer`

- `rate_plan_code`
- `board_code`
- `currency`
- `intersections`

`intersection`

- `room_code`
- `room_code_canonical`
- `board_code`
- `occupancies`
- `prices`
- `availabilities`
- `filters`

### 3.17. Рекомендуемая Декомпозиция Для Elixir/Phoenix

Минимальный набор модулей:

- `Synxis.RPAC.BuildService`
- `Synxis.RPAC.OfferBuilder`
- `Synxis.RPAC.IntersectionBuilder`
- `Synxis.RPAC.OccupancyBuilder`
- `Synxis.RPAC.InventoryReducer`
- `Synxis.RPAC.AvailabilityReducer`
- `Synxis.RPAC.RestrictionMapper`
- `Synxis.RPAC.BookingOffsetReducer`
- `Synxis.RPAC.PriceBuilder`
- `Synxis.RPAC.PricePriorityResolver`
- `Synxis.RPAC.RoomIdentityPolicy`
- `Synxis.RPAC.BuildEligibilityPolicy`
- `Synxis.RPAC.OccupancyOverridePolicy`
- `Synxis.RPAC.CollectionCompiler`

Минимальный flow:

1. build service получает `HotelData`
2. offer builder итерирует `rate_plan_code`
3. board определяется для offer
4. room list фильтруется через eligibility policy
5. descriptive consistency policy отбрасывает inconsistent rooms
6. intersection builder собирает draft intersection
7. occupancy builder определяет occupancies
8. inventory reducer применяет inventory timeline
9. availability reducer применяет CTA/CTD/LOS/status restrictions
10. booking offset reducer добавляет booking-date constraints
11. price builder добавляет prices
12. room identity policy применяет canonical room code
13. collection compiler собирает финальный RPAC

### 3.18. Новые Задачи Для Переписывания Build Layer

#### Задача BL.1. Выделить build orchestration contract

Нужно зафиксировать:

- вход: `HotelData`
- выход: `RpacBuildResult`
- как итерируются rate plans
- где возникают rejects и warnings

#### Задача BL.2. Выделить intersection build contract

Нужно зафиксировать:

- как строится intersection
- какие preconditions обязательны
- когда intersection не создаётся

#### Задача BL.3. Выделить inventory reduction contract

Нужно зафиксировать:

- как notifications сортируются
- как newer overrides older
- как получается final availability timeline

#### Задача BL.4. Выделить availability restriction contract

Нужно зафиксировать:

- как обрабатываются CTA/CTD/master restrictions
- как обрабатывается LOS
- что становится availability, а что filter

#### Задача BL.5. Выделить pricing contract

Нужно зафиксировать:

- как строится `minAdultAge`
- как строятся traveller filters
- как строятся prices из `BaseByGuestAmt`
- как работает price precedence

#### Задача BL.6. Выделить room identity contract

Нужно зафиксировать:

- на каком этапе применяется suffix
- где room code становится canonical
- какие downstream слои обязаны работать уже с canonical room code

### 4. `OTDS Mapping Layer`

Задача слоя:

- превратить provider-specific room/board codes в export-ready сущности
- подготовить данные под OTDS writer

Выход слоя:

- export-ready model

### Подробная Декомпозиция `OTDS Mapping Layer`

Этот слой отвечает не за сам XML writer, а за преобразование provider-specific кодов из `RPAC` в export-ready room/board сущности, которые writer уже может сериализовать без дополнительной бизнес-логики.

В текущем PHP-проекте этот слой живёт между:

- `RPAC compiler`
- `ExportedHotel`
- `Otds writers`

То есть это не build layer и не writer layer, а отдельный mapping/enrichment слой.

### 4.1. Главная Задача Mapping Layer

Нужно преобразовать:

- provider room code
- provider board code
- room descriptive attributes
- board descriptive attributes

в export-ready model, где уже есть:

- booking code
- OTDS type
- export name
- facilities
- stable keys для writer

Фактически на выходе нужен enriched hotel model, пригодный для OTDS serialization без SQL-запросов из writer-а.

### 4.2. Текущий Вход В Mapping Layer

Текущий входной объект:

- [HotelCandidate.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/HotelCandidate.php)

Что в него уже приходит до mapping layer:

- provider code
- hotel code
- external code
- `CollectionCompiler` с intersection-ами

Что mapping layer добавляет в `HotelCandidate`:

- `boardsInfo`
- `roomsInfo`
- позже из этого строится `ExportedHotel`

Это и есть фактическая граница слоя.

### 4.3. Room Mapping Provider

Основные текущие файлы:

- [BasicInfoProvider.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/Preparation/RoomsInfo/BasicInfoProvider.php)
- [InfoProvider.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/Preparation/RoomsInfo/InfoProvider.php)
- [AttachRoomsInfo.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/Preparation/RoomsInfo/AttachRoomsInfo.php)

Логика по файлам:

`BasicInfoProvider.php`

- принимает:
  - `provider`
  - `providerRoomCode`
- читает из БД:
  - `roomtypes_matching.roomtype_code AS bookingCode`
  - `roomtypes.otds_roomtype AS type`
  - `roomtypes.roomtype_description AS name`
- фильтрует только те записи, где:
  - booking code не пустой
  - `otds_roomtype` не пустой
- кэширует результат

Это ключевая mapping-операция:

- provider room code -> export room descriptor

`InfoProvider.php`

- оборачивает `BasicInfoProvider`
- дополнительно подтягивает `facilities`
- возвращает уже enriched room info

`AttachRoomsInfo.php`

- итерирует по всем room codes из compiled RPAC
- для каждого room code пытается получить room info
- если info нет:
  - удаляет все intersections для room
  - пишет log
  - если intersections больше не осталось, reject hotel
- если info есть:
  - записывает её в `HotelCandidate.roomsInfo`

Это означает, что room mapping в текущей системе не optional:

- unmapped room удаляется из export
- если после удаления export становится пустым, отель reject-ится

### 4.4. Board Mapping Provider

Основные текущие файлы:

- [InfoProvider.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/Preparation/BoardsInfo/InfoProvider.php)
- [AddBoardsInfo.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/Preparation/BoardsInfo/AddBoardsInfo.php)

Логика по файлам:

`BoardsInfo/InfoProvider.php`

- принимает:
  - `provider`
  - `providerBoardCode`
- читает из БД:
  - `boardtypes_matching.boardtype_code AS bookingCode`
  - `boardtypes.otds_boardtype AS otdsType`
  - `boardtypes.boardtype_description AS boardName`
- кэширует результат

`AddBoardsInfo.php`

- итерирует по всем board codes из compiled RPAC
- для каждого board code пытается получить descriptive/mapping info
- если board info не найден:
  - удаляет intersections для board
  - пишет log
  - если intersections больше не осталось, reject hotel
- если board info найден:
  - записывает её в `HotelCandidate.boardsInfo`

Это означает, что board mapping тоже не optional:

- unmapped board удаляется из export
- если boards закончились, hotel reject

### 4.5. Текущие Таблицы Mapping Layer

Room mapping опирается на:

- [RoomtypesmatchingTable.php](/home/d.shein/Projects/xres_git/lib/classlib/Model/Standingdata/RoomtypesmatchingTable.php)
- [RoomtypesTable.php](/home/d.shein/Projects/xres_git/lib/classlib/Model/Standingdata/RoomtypesTable.php)

Board mapping опирается на:

- [BoardtypesmatchingTable.php](/home/d.shein/Projects/xres_git/lib/classlib/Model/Standingdata/BoardtypesmatchingTable.php)
- [BoardtypesTable.php](/home/d.shein/Projects/xres_git/lib/classlib/Model/Standingdata/BoardtypesTable.php)

Фактическая логика таблиц:

`roomtypes_matching`

- хранит provider room code
- хранит matched booking code
- связывает provider room с xRes room type

`roomtypes`

- хранит export room type
- хранит export room name
- хранит `otds_roomtype`

`boardtypes_matching`

- хранит provider board code
- хранит matched booking code
- связывает provider board с xRes board type

`boardtypes`

- хранит export board type
- хранит export board name
- хранит `otds_boardtype`

### 4.6. Export-Ready Room Model

Из текущей реализации следует, что export-ready room должен содержать минимум:

- `provider_room_code`
- `bookingCode`
- `type`
- `name`
- `facilities`

Именно это writer потом использует для:

- `Unit.Key`
- `UnitName`
- `UnitType`
- `UnitFacilities`

Значит mapping layer обязан вернуть room уже в таком виде, а не “просто matched roomtype_code”.

### 4.7. Export-Ready Board Model

Из текущей реализации следует, что export-ready board должен содержать минимум:

- `provider_board_code`
- `bookingCode`
- `otdsType`
- `boardName`

Именно это writer потом использует для:

- `Board.Key`
- `BoardCode`
- `BoardName`
- `BoardType`

### 4.8. Aggregation В `HotelCandidate`

Текущий промежуточный объект слоя:

- [HotelCandidate.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/HotelCandidate.php)

Его роль:

- хранить provider-specific hotel context
- хранить RPAC compiler
- накапливать enriched mapping info:
  - `boardsInfo`
  - `roomsInfo`
- быть mutable carrier object между preparing routines

Проблема:

- mapping layer использует mutable sack object
- поля заполняются по шагам
- целостность объекта гарантируется только к моменту создания `ExportedHotel`

В Elixir так делать не нужно.
Нужен immutable export-ready aggregate.

### 4.9. Финальная Export-Ready Модель

Текущий финальный объект слоя:

- [ExportedHotel.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/ExportedHotel.php)

Что он делает:

- компилирует final RPAC collection из compiler
- подтягивает `boardsInfo` и `roomsInfo` из `HotelCandidate`
- делает consistency check:
  - каждый board в RPAC должен иметь info
  - каждый room в RPAC должен иметь info
- предоставляет writer-friendly API:
  - `boardBookingCode(...)`
  - `roomBookingCode(...)`
  - `iterateExportBoards()`
  - `iterateUnitCodes()`
  - `getUnitInfo(...)`
  - `combinationsForRoom(...)`
  - `sellingUnitNodeKey(...)`

Это и есть фактический output текущего mapping layer:

- не raw RPAC
- не XML
- а export-ready hotel aggregate

### 4.10. Граница Между Mapping Layer и Writer Layer

Текущие writer-файлы:

- [BoardWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/OtdsWriting/BoardWriter.php)
- [SellingUnitWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/OtdsWriting/SellingUnitWriter.php)
- [SellingAccomWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/OtdsWriting/SellingAccomWriter.php)
- [AccommodationWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/OtdsWriting/AccommodationWriter.php)

Что важно:

- writer не должен сам искать mapping в БД
- writer уже получает:
  - room booking code
  - board booking code
  - room type
  - board type
  - room/board names
- значит mapping layer обязан завершиться до writer-а полностью

Это надо жёстко сохранить при переносе на Phoenix.

### 4.11. Unmapped Entity Policy

Текущая политика слоя:

- unmapped room:
  - intersections for room удаляются
  - если все rooms вылетели, hotel reject
- unmapped board:
  - intersections for board удаляются
  - если все boards вылетели, hotel reject

Это нужно оформить как отдельный contract:

- `UnmappedEntityPolicy`

Вход:

- rpac hotel
- room mappings
- board mappings

Выход:

- reduced export-ready model
- warnings
- reject reason if empty

### 4.12. Где Сейчас Слой Загрязнён

На текущем PHP-состоянии mapping layer загрязнён следующими вещами:

1. mapping routines мутируют `HotelCandidate`
2. room/board cleanup делает destructive edits compiler-а
3. final consistency check спрятан в `ExportedHotel`
4. writer знает о некоторых key-building правилах, которые логически ближе к export model

При переносе на `Elixir/Phoenix` это нужно разделить:

- mapping resolution
- export model assembly
- reject/warning handling
- writer input shaping

### 4.13. Как Должен Выглядеть Mapping Contract В Elixir

Рекомендуемый контракт:

Вход:

- `RpacBuildResult`
- hotel master context
- room mappings
- board mappings

Выход:

- `ExportReadyHotel`

Где `ExportReadyHotel` содержит:

- hotel identity
- external code
- mapped boards
- mapped rooms
- filtered RPAC combinations
- writer-ready keys

`mapped_room`

- `provider_room_code`
- `booking_code`
- `otds_type`
- `name`
- `facilities`

`mapped_board`

- `provider_board_code`
- `booking_code`
- `otds_type`
- `name`

### 4.14. Рекомендуемая Декомпозиция Для Elixir/Phoenix

Минимальный набор модулей:

- `Synxis.OTDS.MappingService`
- `Synxis.OTDS.RoomMappingProvider`
- `Synxis.OTDS.BoardMappingProvider`
- `Synxis.OTDS.RoomInfoAssembler`
- `Synxis.OTDS.BoardInfoAssembler`
- `Synxis.OTDS.ExportReadyHotelBuilder`
- `Synxis.OTDS.UnmappedEntityPolicy`

Минимальный flow:

1. mapping service получает RPAC result
2. room mapping provider резолвит room mappings
3. board mapping provider резолвит board mappings
4. unmapped entity policy удаляет невозможные intersections
5. room info assembler строит export-ready room model
6. board info assembler строит export-ready board model
7. export-ready hotel builder собирает финальный `ExportReadyHotel`
8. writer получает уже полностью готовую модель

### 4.15. Новые Задачи Для Переписывания Mapping Layer

#### Задача ML.1. Выделить room mapping contract

Нужно зафиксировать:

- как provider room code превращается в booking code
- какие поля обязательны для export room
- что делать при отсутствии mapping

#### Задача ML.2. Выделить board mapping contract

Нужно зафиксировать:

- как provider board code превращается в booking code
- какие поля обязательны для export board
- что делать при отсутствии mapping

#### Задача ML.3. Выделить export-ready hotel contract

Нужно зафиксировать:

- какие поля должны быть в финальной модели
- какие consistency checks обязательны
- какие writer methods или их эквиваленты нужны downstream

#### Задача ML.4. Выделить unmapped entity policy

Нужно зафиксировать:

- когда удаляется только board
- когда удаляется только room
- когда reject-ится весь hotel
- какие warning/reject reasons пишутся

### 5. `OTDS Export Layer`

Задача слоя:

- сериализовать данные в OTDS XML

Выход слоя:

- `OTDS XML`

### Подробная Декомпозиция `OTDS Export Layer`

Этот слой отвечает уже не за mapping и не за build, а за чистую serialization-задачу:

- взять export-ready model
- открыть XML writer
- последовательно записать OTDS nodes
- закрыть документ
- сохранить файл в staging/archive flow

Это должен быть максимально “тупой” слой.
Если в writer-е появляется SQL, mapping resolution или RPAC filtering, значит граница слоёв нарушена.

### 5.1. Главная Точка Входа Export Layer

Основной файл:

- [HotelFileWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/HotelFileWriter.php)

Что делает:

- получает destination, stage, export params и logger
- получает список `ExportedHotel`
- открывает XML writer для hotel file
- для каждого hotel:
  - при необходимости открывает новый `Accommodation`
  - пишет `SellingAccom`
- в конце закрывает XML document
- если не было ни одного hotel:
  - удаляет пустой hotel file

Это текущая orchestration layer для hotel XML serialization.

Что нужно вынести в Elixir:

- `Synxis.OTDS.Export.HotelXmlWriter`

Вход:

- destination
- list of `ExportReadyHotel`
- export params

Выход:

- path to generated OTDS hotel XML

### 5.2. Глобальный XML Envelope

Текущая envelope-логика живёт в:

- [HotelFileWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/HotelFileWriter.php)
- [BaseFilesWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/BaseFilesWriter.php)

`HotelFileWriter.php` отвечает за hotel-payload document:

- открывает XML writer
- пишет root node:
  - `Otds`
  - `Version="2.1.2"`
  - `UpdateMode="Merge"`
  - `xmlns`
  - `xmlns:xsi`
  - `xsi:schemaLocation`
- создаёт:
  - `Brands`
  - `Accommodations`

`BaseFilesWriter.php` отвечает за вспомогательные файлы:

- `delivery.xml`
- `base.xml`

Это уже не hotel serialization в узком смысле, но это часть OTDS export packaging.

Что нужно вынести в Elixir:

- `Synxis.OTDS.Export.EnvelopeWriter`
- `Synxis.OTDS.Export.BaseFilesWriter`

### 5.3. Accommodation Node Writer

Текущий файл:

- [AccommodationWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/OtdsWriting/AccommodationWriter.php)

Что делает:

- пишет `Accommodation -> Properties`
- пишет hotel-level master data:
  - `AccommodationName`
  - `Giata` reference
  - category
  - address
  - region
- пишет flex cancellation addon block, если он есть

Это означает, что writer ожидает от upstream уже готовые:

- hotel master data
- address structure
- region info
- flex cancellation data

Writer сам их не собирает и не валидирует.

Что нужно вынести в Elixir:

- `Synxis.OTDS.Export.AccommodationWriter`

Вход:

- `ExportReadyHotel`
- xml writer
- export params

### 5.4. SellingAccom Writer

Текущий файл:

- [SellingAccomWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/OtdsWriting/SellingAccomWriter.php)

Что делает:

- создаёт `SellingAccom`
- пишет booking params:
  - `ServiceCode`
  - `RequestCode`
- пишет hotel-level properties:
  - special services
  - transfers
- пишет boards
- пишет units

Это главный writer service-area сущности.

Структурно он уже знает, что:

- один hotel = один `SellingAccom`
- внутри `SellingAccom` живут:
  - boards
  - units
  - selling units

Что нужно вынести в Elixir:

- `Synxis.OTDS.Export.SellingAccomWriter`

### 5.5. Board Writer

Текущий файл:

- [BoardWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/OtdsWriting/BoardWriter.php)

Что делает:

- пишет `Board`
- пишет board booking block:
  - `ServiceFeatureCode`
  - `BoardCode`
- пишет board properties:
  - `BoardName`
  - `BoardType`

Это важно:

- writer не знает provider board code
- writer работает уже только с export-ready board info

Значит mapping layer должен завершиться полностью до входа в writer.

Что нужно вынести в Elixir:

- `Synxis.OTDS.Export.BoardWriter`

### 5.6. Unit Writer

Часть unit serialization живёт в:

- [SellingAccomWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/OtdsWriting/SellingAccomWriter.php)

Что делает:

- итерирует export unit codes
- создаёт `Unit`
- пишет:
  - `UnitName`
  - `UnitType`
  - `UnitFacilities`
- затем для каждой комбинации комнаты пишет `SellingUnit`

Это означает, что export layer использует две сущности:

- logical room unit
- concrete sellable room/board intersection

Что нужно вынести в Elixir:

- `Synxis.OTDS.Export.UnitWriter`

### 5.7. SellingUnit Writer

Текущий файл:

- [SellingUnitWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/OtdsWriting/SellingUnitWriter.php)

Что делает:

- создаёт `SellingUnit`
- пишет room booking block:
  - `RoomCode`
- добавляет board filter:
  - `global:Board`
- сериализует все filters из combination
- сериализует:
  - occupancies
  - prices
  - availabilities

Это ключевой момент export-слоя:

- writer не строит filters, prices, availabilities
- он только сериализует уже готовые RPAC combination parts в OTDS XML

Значит build layer обязан отдать уже финальную normalized combination model.

Что нужно вынести в Elixir:

- `Synxis.OTDS.Export.SellingUnitWriter`

### 5.8. Grouping Policy По `Accommodation`

Текущая логика группировки живёт в:

- [HotelFileWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/HotelFileWriter.php)

Что происходит:

- если у двух provider hotels одинаковый `externalCode`
  - они пишутся в один `Accommodation`
- если `externalCode` меняется
  - предыдущий `Accommodation` закрывается
  - открывается новый

Это важная export policy, а не просто техническая деталь.

Её нужно явно сохранить при переносе:

- `AccommodationGroupingPolicy`

Что нужно вынести в Elixir:

- `Synxis.OTDS.Export.AccommodationGroupingPolicy`

### 5.9. Key-Building Policy

Текущие key-building правила размазаны между:

- [ExportedHotel.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/ExportedHotel.php)
- [HotelFileWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/HotelFileWriter.php)
- [SellingAccomWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/OtdsWriting/SellingAccomWriter.php)
- [SellingUnitWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/OtdsWriting/SellingUnitWriter.php)

Какие ключи строятся:

- `Accommodation.Key`
- `SellingAccom.Key`
- `Board.Key`
- `Unit.Key`
- `SellingUnit.Key`

Это отдельная policy, и writer не должен строить её ad hoc.

Что нужно вынести в Elixir:

- `Synxis.OTDS.Export.KeyPolicy`

### 5.10. Hotel Export Flow Внутри Destination Export

Текущий более верхний orchestration-файл:

- [DestinationFilesWriter.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/DestinationFilesWriter.php)

Что делает:

- запускает hotel writer
- при необходимости запускает flight writer
- если flights обязательны, но не были построены:
  - удаляет hotel file

Это уже не serialization одного hotel, а orchestration export components per destination.

Для hotel OTDS export важно:

- hotel XML может быть валиден сам по себе
- но delivery policy может потом удалить его, если нет flight part

Это надо отделить от самой XML serialization.

### 5.11. Archive и Stage Layer

Текущий файл:

- [ArchiveCreator.php](/home/d.shein/Projects/xres_git/modules/otds/src/Payload/ArchiveCreator.php)

Что делает:

- создаёт stage directory
- пишет base files
- спавнит destination export jobs
- после окончания собирает архив
- очищает stage

Это не сам OTDS writer, но это delivery wrapper вокруг export layer.

При переносе на Phoenix это лучше выделить отдельно:

- export serialization
- export packaging
- export delivery

### 5.12. Encoding Layer

Текущий файл:

- [Encoder.php](/home/d.shein/Projects/xres_git/modules/otds/src/Encoder.php)

Что делает:

- гарантирует UTF-8 для строк, пришедших из xRes DB

Важно:

- encoding normalization должна происходить до XML writing
- writer не должен сам решать encoding problems на лету

В Elixir это нужно учесть отдельно:

- `Synxis.OTDS.Export.Encoding`

### 5.13. Что Writer Ожидает Уже Готовым

К моменту входа в export layer должны быть уже готовы:

- hotel master data
- room mapping
- board mapping
- unit facilities
- RPAC combinations
- prices
- availabilities
- filters
- occupancies
- special services
- transfers
- flex cancellation

Если writer вынужден что-то “дособирать”, значит слой выше не закончен.

### 5.14. Где Сейчас Слой Загрязнён

На текущем PHP-состоянии export layer загрязнён следующими вещами:

1. grouping policy по `Accommodation` живёт внутри file writer
2. key-building rules размазаны между model и writers
3. destination-level orchestration тесно связано с file lifecycle
4. часть product-level envelope logic лежит не рядом с hotel writer, а в `BaseFilesWriter`

При переносе на `Elixir/Phoenix` это лучше разделить на:

- hotel xml serialization
- base files serialization
- destination orchestration
- archive packaging
- key policy

### 5.15. Как Должен Выглядеть Export Contract В Elixir

Рекомендуемый контракт:

Вход:

- `ExportReadyHotel`
- `ExportParams`
- destination context

Выход:

- OTDS XML fragment или OTDS hotel file

Writer contract должен быть таким:

- writer не делает SQL-запросы
- writer не меняет business model
- writer не отбрасывает intersections по business reasons
- writer только сериализует уже подготовленные данные

### 5.16. Рекомендуемая Декомпозиция Для Elixir/Phoenix

Минимальный набор модулей:

- `Synxis.OTDS.Export.HotelXmlWriter`
- `Synxis.OTDS.Export.EnvelopeWriter`
- `Synxis.OTDS.Export.AccommodationWriter`
- `Synxis.OTDS.Export.SellingAccomWriter`
- `Synxis.OTDS.Export.BoardWriter`
- `Synxis.OTDS.Export.UnitWriter`
- `Synxis.OTDS.Export.SellingUnitWriter`
- `Synxis.OTDS.Export.KeyPolicy`
- `Synxis.OTDS.Export.AccommodationGroupingPolicy`
- `Synxis.OTDS.Export.BaseFilesWriter`
- `Synxis.OTDS.Export.ArchiveAssembler`

Минимальный flow:

1. export service получает destination и export-ready hotels
2. envelope writer открывает OTDS document
3. grouping policy группирует hotels по `externalCode`
4. accommodation writer пишет hotel-level node
5. selling accom writer пишет service-area node
6. board writer сериализует boards
7. unit writer сериализует units
8. selling unit writer сериализует combinations, prices, availabilities, filters
9. envelope writer закрывает document
10. archive assembler складывает XML в export artifact

### 5.17. Новые Задачи Для Переписывания Export Layer

#### Задача EL.1. Выделить hotel XML writer contract

Нужно зафиксировать:

- входную модель writer-а
- какие XML nodes writer обязан писать
- какие данные writer считает already resolved

#### Задача EL.2. Выделить accommodation grouping contract

Нужно зафиксировать:

- когда hotels группируются в один `Accommodation`
- по какому ключу происходит grouping
- когда `Accommodation` должен закрываться

#### Задача EL.3. Выделить key policy contract

Нужно зафиксировать:

- как строятся keys:
  - `Accommodation`
  - `SellingAccom`
  - `Board`
  - `Unit`
  - `SellingUnit`
- какие ключи должны быть stable

#### Задача EL.4. Выделить envelope/base-files contract

Нужно зафиксировать:

- как строится `Otds` root
- какие base files обязательны
- как version/schema/config values задаются

#### Задача EL.5. Выделить archive packaging contract

Нужно зафиксировать:

- как stage directory формируется
- как destination files собираются
- как archive финализируется

## Доменные Сущности

### 1. `SynxisHotelBundle`

Поля:

- `provider`
- `environment`
- `hotel_code`
- `rates_xml`
- `inventory_xml`
- `availabilities_xml`
- `hotel_descriptive_info_xml`
- `downloaded_at`
- `validation_status`

### 2. `HotelData`

Должен содержать:

- hotel
- rooms
- boards
- rate plans
- currency
- occupancy constraints
- child/adult age semantics
- descriptive room whitelist

### 3. `RpacHotel`

Содержит:

- provider
- hotel
- version
- currency
- collection of offers

### 4. `RpacOffer`

Содержит:

- `rate_plan_code`
- `board_code`
- intersections

### 5. `RpacIntersection`

Содержит:

- `room_code`
- `board_code`
- occupancies
- prices
- availabilities
- filters

### 6. `RpacPrice`

Содержит:

- period
- amount
- currency
- pax/age condition
- priority/weight

### 7. `RpacAvailability`

Содержит:

- period
- status
- CTA/CTD/LOS restrictions

### 8. `RpacFilter`

Содержит:

- occupancy filter
- traveller condition
- LOS condition
- booking restriction

## Минимальная Схема Таблиц

### 1. `synxis_hotel_bundle`

Поля:

- `id`
- `provider`
- `environment`
- `hotel_code`
- `rates_payload` или `rates_path`
- `inventory_payload` или `inventory_path`
- `availabilities_payload` или `availabilities_path`
- `descriptive_payload` или `descriptive_path`
- `status`
- `created_at`
- `updated_at`

### 2. `provider_rateplan_board_mapping`

Поля:

- `id`
- `provider`
- `environment`
- `hotel_code`
- `rate_plan_code`
- `board_code`
- `created_at`
- `updated_at`

Назначение:

- связка `rate plan -> meal plan/board`
- для SynXis это обязательная таблица

### 3. `provider_room_mapping`

Поля:

- `id`
- `provider`
- `hotel_code`
- `provider_room_code`
- `provider_room_code_canonical`
- `booking_code`
- `room_type`
- `room_name`
- `created_at`
- `updated_at`

### 4. `provider_board_mapping`

Поля:

- `id`
- `provider`
- `provider_board_code`
- `booking_code`
- `board_type`
- `board_name`
- `created_at`
- `updated_at`

### 5. `rpac_hotels`

Поля:

- `id`
- `provider`
- `hotel_code`
- `version`
- `currency`
- `bundle_id`
- `status`
- `created_at`

### 6. `rpac_offers`

Поля:

- `id`
- `rpac_hotel_id`
- `rate_plan_code`
- `board_code`
- `description`

### 7. `rpac_intersections`

Поля:

- `id`
- `rpac_offer_id`
- `room_code`
- `room_code_canonical`
- `board_code`
- `min_adult_age`
- `max_pax`

### 8. `rpac_prices`

Поля:

- `id`
- `intersection_id`
- `date_from`
- `date_to`
- `amount`
- `currency`
- `guest_count`
- `age_qualifying_code`
- `min_age`
- `max_age`
- `weight`

### 9. `rpac_availabilities`

Поля:

- `id`
- `intersection_id`
- `date_from`
- `date_to`
- `availability_type`

### 10. `rpac_filters`

Поля:

- `id`
- `intersection_id`
- `filter_type`
- `payload_json`

## Ключевые Правила Для `Synxis`

### 1. Room Identity

Нужно сразу зафиксировать:

- исходный provider room code: `room_code`
- canonical room code: `room_code + hotel_code`

### 2. Board Identity

Нужно зафиксировать:

- board code для SynXis берётся из `meal_plan`
- источник board для build-а: mapping `rate_plan_code -> board_code`

### 3. Offer Identity

Нужно зафиксировать:

- offer = `hotel_code + rate_plan_code + board_code`

### 4. Bundle Completeness

Отель нельзя пускать дальше, если отсутствует хотя бы один обязательный XML.

## Сквозная Логика

1. Скачать 4 обязательных XML.
2. Собрать `SynxisHotelBundle`.
3. Провалидировать bundle.
4. Построить `HotelData`.
5. Для каждого `rate_plan_code` найти `board_code`.
6. Для каждого rate plan извлечь список rooms.
7. Отфильтровать rooms по descriptive data.
8. Построить `RpacOffer`.
9. Построить `RpacIntersection` для `room + board`.
10. Добавить occupancy rules.
11. Добавить inventories.
12. Добавить availabilities.
13. Добавить prices.
14. Применить canonical room identity.
15. Сохранить `RPAC`.
16. Применить OTDS mappings.
17. Сгенерировать `OTDS XML`.

## P0 Задачи

1. Описать `SynxisHotelBundle contract`.
2. Описать `HotelData contract`.
3. Описать `Synxis -> RPAC build contract`.
4. Описать `RPAC -> OTDS mapping contract`.
5. Зафиксировать room identity policy.
6. Зафиксировать board identity policy.
7. Спроектировать минимальную DB schema.

## Acceptance Criteria

1. Для одного `hotel_code` принимается полный bundle из 4 XML.
2. Из bundle строится один валидный `HotelData`.
3. Из `HotelData` строится один валидный `RPAC`.
4. Для всех intersections определены room/board identities.
5. Для всех exportable rooms и boards существуют mappings.
6. На выходе получается один корректный `OTDS XML`.

## Исполнимые Спецификации, Которых Не Хватало

Ниже зафиксированы обязательные greenfield-разделы, без которых документ остаётся архитектурным outline, но не implementation-grade specification.

### 1. Формальные Контракты Данных

Для всех основных доменных моделей должны существовать не только списки полей, но и жёсткие правила:

- тип поля
- обязательность поля
- nullable/non-nullable semantics
- cardinality
- default values
- допустимые enum values
- пример минимального валидного payload

Минимальный contract set:

- `SynxisHotelBundle`
- `HotelData`
- `RpacBuildResult`
- `ExportReadyHotel`
- `BuildReject`
- `BuildWarning`

#### 1.1. `SynxisHotelBundle` Contract

```yaml
SynxisHotelBundle:
  provider: string, required, const="synxis"
  environment: string, required, enum=[prod, stage, test]
  hotel_code: string, required, non-empty
  rates_xml: string, required, raw xml
  inventory_xml: string, required, raw xml
  availabilities_xml: string, required, raw xml
  hotel_descriptive_info_xml: string, required, raw xml
  downloaded_at: datetime, required, utc
  validation_status: string, required, enum=[
    valid,
    invalid_missing_file,
    invalid_empty_file,
    invalid_xml,
    invalid_hotel_mismatch
  ]
  source_request_ids: list<string>, optional
  checksum: string, required
```

Минимальный валидный bundle:

```json
{
  "provider": "synxis",
  "environment": "prod",
  "hotel_code": "HTL123",
  "rates_xml": "<Rates>...</Rates>",
  "inventory_xml": "<Inventory>...</Inventory>",
  "availabilities_xml": "<Availabilities>...</Availabilities>",
  "hotel_descriptive_info_xml": "<OTA_HotelDescriptiveInfoRS>...</OTA_HotelDescriptiveInfoRS>",
  "downloaded_at": "2026-05-08T10:15:00Z",
  "validation_status": "valid",
  "checksum": "sha256:..."
}
```

#### 1.2. `HotelData` Contract

```yaml
HotelData:
  provider: string, required
  environment: string, required
  hotel_code: string, required
  currency: string, required, iso4217
  rate_plans: list<RatePlan>, required, min=1
  rooms: list<Room>, required, min=1
  boards: list<Board>, required, min=1
  descriptive_rooms: list<string>, required
  child_policy: ChildPolicy, required
  occupancy_constraints: list<OccupancyConstraint>, required
  mapping_metadata: MappingMetadata, optional
```

Правила:

- `rate_plan.code` уникален в пределах `hotel_code`
- `room.provider_room_code` уникален в пределах `hotel_code`
- `board.provider_board_code` уникален в пределах `hotel_code`
- все `rate_plan.room_codes` должны ссылаться на существующие `rooms`
- `currency` должна быть одна на весь `HotelData`; multi-currency bundle reject-ится

#### 1.3. `RpacBuildResult` Contract

```yaml
RpacBuildResult:
  hotel_code: string, required
  provider: string, required
  version: integer, required, >0
  currency: string, required
  offers: list<RpacOffer>, required
  warnings: list<BuildWarning>, required
  rejects: list<BuildReject>, required
  stats: BuildStats, required
```

Правила:

- `offers` может быть пустым только если build завершается terminal reject-ом hotel-level
- каждый `RpacOffer` идентифицируется как `hotel_code + rate_plan_code + board_code`
- каждый `RpacIntersection` идентифицируется как `offer_id + room_code_canonical`

#### 1.4. `ExportReadyHotel` Contract

```yaml
ExportReadyHotel:
  hotel_code: string, required
  external_code: string, required
  currency: string, required
  mapped_rooms: list<MappedRoom>, required
  mapped_boards: list<MappedBoard>, required
  combinations: list<ExportCombination>, required
  warnings: list<BuildWarning>, required
  empty_reason: string, optional
```

Правила:

- writer получает только export-ready модель
- writer не делает fallback mapping
- `combinations` не могут ссылаться на unmapped room или board

### 2. Lifecycle И State Machine

Статусы должны быть формализованы отдельно для bundle, RPAC build и export artifact.

#### 2.1. `SynxisHotelBundle` Lifecycle

Допустимые статусы:

- `download_pending`
- `downloaded`
- `validated`
- `invalid`
- `canonicalized`
- `archived`

Переходы:

1. `download_pending -> downloaded`
2. `downloaded -> validated`
3. `downloaded -> invalid`
4. `validated -> canonicalized`
5. `canonicalized -> archived`

Недопустимо:

- `invalid -> validated` без нового bundle version
- `downloaded -> archived` без explicit validation

#### 2.2. `rpac_hotels.status` Lifecycle

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

Правила:

- `failed` означает техническую ошибку pipeline
- `rejected` означает детерминированную бизнес-невозможность строить export
- повторный run по тому же `hotel_code` создаёт новую `version`, а не мутирует старую запись

### 3. Идемпотентность И Versioning

Нужно явно зафиксировать:

- bundle uniqueness key = `provider + environment + hotel_code + checksum`
- build uniqueness key = `provider + environment + hotel_code + bundle_id`
- export uniqueness key = `provider + environment + hotel_code + rpac_version + destination`

Правила:

- одинаковый bundle по checksum не должен пересобираться второй раз без force flag
- новый bundle для того же `hotel_code` всегда создаёт новую `rpac_hotels.version`
- export перезапускается идемпотентно для одной и той же `rpac_version`
- ручной replay разрешён только через новую execution record

### 4. Error Taxonomy

Все ошибки и business rejects должны иметь machine-readable code.

#### 4.1. Transport Errors

- `transport_timeout`
- `transport_ssl_error`
- `transport_auth_error`
- `transport_endpoint_unavailable`
- `transport_invalid_soap_response`

#### 4.2. Input Validation Errors

- `invalid_missing_file`
- `invalid_empty_file`
- `invalid_xml`
- `invalid_hotel_mismatch`
- `invalid_namespace_missing`

#### 4.3. Canonical Parse Errors

- `parse_rates_failed`
- `parse_inventory_failed`
- `parse_availabilities_failed`
- `parse_descriptive_failed`
- `currency_not_resolved`
- `child_policy_not_resolved`
- `rateplan_board_mapping_missing`

#### 4.4. Build Rejects

- `reject_room_not_in_descriptive`
- `reject_room_unmapped`
- `reject_board_unmapped`
- `reject_rateplan_without_intersections`
- `reject_intersection_removed_by_occupancy`
- `reject_price_not_built`
- `reject_availability_not_built`
- `reject_hotel_empty_after_filters`

#### 4.5. Export Errors

- `export_invalid_model`
- `export_xml_write_failed`
- `export_encoding_failed`
- `export_archive_failed`

#### 4.6. Retry Policy

Retryable:

- `transport_timeout`
- `transport_endpoint_unavailable`
- `export_archive_failed`

Non-retryable:

- `transport_auth_error`
- `invalid_xml`
- `invalid_hotel_mismatch`
- `rateplan_board_mapping_missing`
- все `reject_*`

### 5. DB Constraints И Storage Policy

Минимальная схема таблиц должна быть дополнена ограничениями.

#### 5.1. Constraints

`synxis_hotel_bundle`

- unique: `provider, environment, hotel_code, checksum`
- index: `hotel_code, created_at desc`

`provider_rateplan_board_mapping`

- unique: `provider, environment, hotel_code, rate_plan_code`
- foreign key на hotel master optional, если hotel registry существует

`provider_room_mapping`

- unique: `provider, hotel_code, provider_room_code_canonical`
- index: `provider, hotel_code, booking_code`

`provider_board_mapping`

- unique: `provider, provider_board_code`

`rpac_hotels`

- unique: `provider, hotel_code, version`
- foreign key: `bundle_id -> synxis_hotel_bundle.id`
- index: `hotel_code, status, created_at desc`

`rpac_offers`

- unique: `rpac_hotel_id, rate_plan_code, board_code`

`rpac_intersections`

- unique: `rpac_offer_id, room_code_canonical`

#### 5.2. Payload Storage Policy

Нужно выбрать один вариант и зафиксировать его как стандарт:

- либо raw XML хранится в DB
- либо в object storage / filesystem, а в DB хранится только `path`, `checksum`, `size_bytes`

Greenfield recommendation:

- raw XML хранить вне main relational DB
- в DB хранить:
  - `path`
  - `checksum`
  - `size_bytes`
  - `content_type`

#### 5.3. Retention Policy

- raw bundle хранить минимум `90 days`
- export artifacts хранить минимум `180 days`
- failed/rejected execution logs хранить минимум `180 days`

### 6. Mapping Governance

Нужно отдельно зафиксировать operating model для mappings.

#### 6.1. Source Of Truth

- `provider_rateplan_board_mapping` является source of truth для board resolution
- `provider_room_mapping` является source of truth для room export mapping
- `provider_board_mapping` является source of truth для board export mapping

#### 6.2. Missing Mapping Policy

При отсутствии mapping:

- room mapping отсутствует -> intersection reject-ится с `reject_room_unmapped`
- board mapping отсутствует -> intersection reject-ится с `reject_board_unmapped`
- если после reject-ов export пустой -> hotel получает `reject_hotel_empty_after_filters`

#### 6.3. Ownership

Нужно определить владельца mapping tables:

- product/data operations владеет business correctness mapping-ов
- pipeline владеет только применением mapping-ов, но не invent-ит их на лету

#### 6.4. Draft Mapping Creation

Разрешено:

- писать warning/report о новых unmapped codes

Запрещено:

- автоматически создавать production mapping без human approval

### 7. OTDS Output Contract

Нужно зафиксировать не только слои writer-а, но и точное соответствие полей.

#### 7.1. Глобальные Инварианты

- root node всегда `Otds`
- `Version` фиксирован и задаётся config-ом export profile
- `UpdateMode` фиксирован и задаётся config-ом export profile
- `xsi:schemaLocation` фиксирован и versioned
- output encoding всегда `UTF-8`

#### 7.2. RPAC -> OTDS Mapping Matrix

Минимальная таблица соответствия:

- `ExportReadyHotel.external_code -> Accommodation/@Code`
- `MappedRoom.booking_code -> Unit/@Code`
- `MappedBoard.booking_code -> Board/@Code`
- `RpacPrice.amount -> SellingUnit/Price`
- `RpacAvailability.status -> SellingUnit availability attributes`
- `RpacFilter.payload_json -> SellingUnit restriction nodes`

#### 7.3. Writer Boundary

Writer не имеет права:

- читать mapping tables
- применять business filters
- изменять identity codes
- молча пропускать invalid combinations

Writer обязан:

- падать с `export_invalid_model`, если получает комбинацию с отсутствующим mapped room/board
- детерминированно сериализовать одинаковый input в одинаковый XML

### 8. Edge Cases И Precedence Rules

Документ должен фиксировать спорные сценарии.

#### 8.1. Currency

- если в bundle встречается более одной currency, hotel reject-ится

#### 8.2. Overlapping Price Periods

- при overlapping price periods выигрывает запись с более высоким `weight`
- при равном `weight` build завершается `reject_price_not_built`

#### 8.3. Availability Precedence

Порядок применения ограничений:

1. inventory
2. open/close status
3. CTA/CTD
4. LOS restrictions
5. booking offsets

#### 8.4. Empty Export

- если после mapping/filtering/export eligibility не осталось ни одной combination, hotel получает `rejected`, а пустой XML не пишется

### 9. Observability И Operations

Для production pipeline нужны обязательные технические требования.

#### 9.1. Structured Logging

Каждый шаг обязан логировать:

- `provider`
- `environment`
- `hotel_code`
- `bundle_id`
- `rpac_version`
- `execution_id`
- `step`
- `status`
- `error_code`

#### 9.2. Metrics

Минимальные метрики:

- bundles_downloaded_total
- bundles_invalid_total
- hoteldata_built_total
- rpac_built_total
- hotels_rejected_total
- export_written_total
- transport_request_duration_ms
- build_duration_ms
- export_duration_ms

#### 9.3. Replayability

Нужны отдельные команды:

- replay bundle validation
- rebuild RPAC from existing bundle
- re-export OTDS from existing RPAC version

### 10. Test Artifacts И Acceptance Fixtures

Текущих high-level acceptance criteria недостаточно; нужны фиксированные test artifacts.

#### 10.1. Обязательные Fixtures

- 1 happy-path hotel bundle
- 1 hotel bundle с missing file
- 1 hotel bundle с hotel mismatch
- 1 hotel bundle с inconsistent descriptive rooms
- 1 hotel bundle с unmapped room
- 1 hotel bundle с overlapping price periods

#### 10.2. Обязательные Golden Outputs

- canonical `HotelData` snapshot
- `RpacBuildResult` snapshot
- final `OTDS XML` golden file

#### 10.3. Contract Tests

Нужны tests следующих уровней:

- transport contract tests
- bundle validator tests
- canonical parser tests
- build policy tests
- mapping policy tests
- export writer snapshot tests

### 11. Security И Config Policy

Нужно отдельно зафиксировать:

- credentials никогда не хранятся в spec/static config файлах
- secrets поставляются через runtime secret store
- SOAP credentials versioned и rotatable
- environment separation обязательна для `prod`, `stage`, `test`
- timeout values задаются централизованно через config profile

### 12. Performance Envelope

Минимально должны быть зафиксированы limits:

- max bundle size
- max XML parse time per file
- max download retries
- max concurrent hotel fetch/build/export jobs
- max OTDS file size before file rotation

Рекомендуемые стартовые значения:

- `download retry count = 3`
- `transport timeout = 30s`
- `max concurrent hotels per pipeline worker pool = 10`
- `max xml parse time per document = 5s`

### 13. Decision Log

Чтобы спецификация не деградировала, для спорных правил нужен decision log:

- почему `room_code_canonical = room_code + hotel_code`
- почему `rate_plan_code -> board_code` идёт через mapping, а не через direct XML field
- почему multi-currency hotel reject-ится
- почему writer не делает fallback filtering

Каждое такое решение должно иметь:

- decision id
- date
- owner
- rationale
- alternatives considered
- impact

### 14. Минимальный Definition Of Done Для Greenfield Spec

Спецификация считается завершённой только если:

1. для всех core entities есть формальные contracts с типами и обязательностью
2. для всех statuses описаны state transitions
3. для всех reject/error cases есть machine-readable codes
4. для DB описаны unique constraints и indexes
5. для mapping-ов описан source of truth и ownership
6. для export-а зафиксирован RPAC -> OTDS field mapping
7. есть минимум один end-to-end fixture и golden output
8. есть replay/observability requirements
9. есть performance и security baseline
10. документ позволяет независимо реализовать pipeline без чтения legacy PHP

## Административные Формы И Экраны

Ниже зафиксирован минимальный admin UI contract для `Synxis -> RPAC -> OTDS`.

Главный принцип:

- руками администрируются только mappings и export policies
- pipeline artifacts не редактируются вручную
- bundle, `HotelData`, `RPAC`, `OTDS export result` должны быть наблюдаемыми, но не editable

Это не ломает текущую модель документа, потому что соответствует уже определённым сущностям:

- `provider_rateplan_board_mapping`
- `provider_room_mapping`
- `provider_board_mapping`
- `synxis_hotel_bundle`
- `rpac_hotels`

### 1. Что Уже Реально Есть В Коде

#### 1.1. Synxis RatePlan -> MealPlan Administration

В коде уже существует административный CRUD для SynXis contract details:

- [modules/xadmin/application/modules/standingdata/controllers/SynxisContractDetailsController.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/standingdata/controllers/SynxisContractDetailsController.php)
- [modules/xadmin/classes/Hotel/SynxisContractDetails/Forms/AbstractForm.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/SynxisContractDetails/Forms/AbstractForm.php)
- [modules/xadmin/classes/Hotel/SynxisContractDetails/Forms/Add.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/SynxisContractDetails/Forms/Add.php)
- [modules/xadmin/classes/Hotel/SynxisContractDetails/Forms/Edit.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/SynxisContractDetails/Forms/Edit.php)
- [modules/xadmin/classes/Hotel/SynxisContractDetails/Db/ContractDetails.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/SynxisContractDetails/Db/ContractDetails.php)
- [lib/classlib/Db/Hotel/Tables/SynxisContractDetails.php](/home/d.shein/Projects/xres_git/lib/classlib/Db/Hotel/Tables/SynxisContractDetails.php)
- [lib/classlib/Hotel/SynXis/DataProvider/ContractDetails.php](/home/d.shein/Projects/xres_git/lib/classlib/Hotel/SynXis/DataProvider/ContractDetails.php)

Из анализа текущих файлов видно:

- UI уже администрирует связку `hotel + environment + rate_code -> meal_plan`
- поле `meal_plan` заполняется из environment-specific справочника
- `hotel_name` уже подтягивается как read-only display field
- существует проверка uniqueness на уровне `hotelId + environment + rateCode`

Значит:

- существующий CRUD логически соответствует greenfield-сущности `provider_rateplan_board_mapping`
- переизобретать отдельную новую форму для `rate_plan_code -> board_code` не нужно
- достаточно в новой архитектуре считать текущую форму административным фасадом над этим mapping

#### 1.2. OTDS Hotel Export Configuration

В коде уже существует административный CRUD для OTDS export policies:

- [modules/xadmin/application/modules/export/controllers/SeasonsHotelOtdsController.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/export/controllers/SeasonsHotelOtdsController.php)
- [modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Forms/AbstractForm.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Forms/AbstractForm.php)
- [modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Forms/Add.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Forms/Add.php)
- [modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Forms/Edit.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Forms/Edit.php)
- [modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Forms/MultiEdit.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Forms/MultiEdit.php)
- [modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Db/SeasonsHotelOtds.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Db/SeasonsHotelOtds.php)
- [lib/classlib/Db/Hotel/Tables/ExportSeasonsHotelOtds.php](/home/d.shein/Projects/xres_git/lib/classlib/Db/Hotel/Tables/ExportSeasonsHotelOtds.php)

Из анализа текущих файлов видно:

- уже есть hotel-level export policy editing
- уже есть mass edit support
- уже есть валидации для:
  - `external_hotel_code`
  - `offers_start_min_days < offers_start_max_days`
  - `season_date_min <= season_date_max`
  - CSV формата `travel_durations`
- уже существует duplicate detection по полному набору export policy полей

Значит:

- существующий CRUD нужно сохранить
- его не нужно смешивать с RPAC build logic
- это отдельная admin form для downstream OTDS export policy
- поле `external_hotel_code` в этой форме не является master source of truth для hotel identity; оно служит lookup key для policy, привязанной к уже существующему hotel matching

#### 1.3. Hotel Matching / External Code Administration

В текущем legacy `external_code` живёт прежде всего в `hotel_matching` и именно оттуда попадает в OTDS export.

Связанные файлы:

- [modules/otds/src/Hotels/HotelsSelector.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/HotelsSelector.php)
- [modules/otds/src/Hotels/HotelCandidate.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/HotelCandidate.php)
- [modules/xadmin/application/modules/zhotels/forms/Overview.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/zhotels/forms/Overview.php)
- [modules/xadmin/application/modules/zhotels/controllers/HotelsController.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/zhotels/controllers/HotelsController.php)
- [modules/xadmin/classes/Hotel/Db/TableRelations/HotelMatching.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/Db/TableRelations/HotelMatching.php)

Из анализа текущих файлов видно:

- `HotelsSelector` выбирает export candidates из `hotel_matching`
- `HotelCandidate` требует непустой `externalCode` уже в конструкторе
- `external_code` не вычисляется в writer-е и не берётся из `ExportSeasonsHotelOtds`
- в legacy admin уже есть формы/экраны, где `external_code` отображается и редактируется

Значит:

- source of truth для OTDS hotel identity сейчас находится в `hotel_matching.external_code`
- `ExportSeasonsHotelOtds.external_hotel_code` является policy lookup key, а не master identity field
- greenfield-spec должен сохранять это различие

#### 1.4. Room Type Filter Administration

В коде уже существует отдельный legacy CRUD для room type filtering:

- [modules/xadmin/application/modules/export/controllers/RoomtypefilterController.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/export/controllers/RoomtypefilterController.php)
- [modules/xadmin/application/modules/export/forms/Roomtypefilter.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/export/forms/Roomtypefilter.php)
- [lib/classlib/Model/Export/RoomTypeFilter.php](/home/d.shein/Projects/xres_git/lib/classlib/Model/Export/RoomTypeFilter.php)
- [lib/classlib/RoomTypeFilter/Mapper.php](/home/d.shein/Projects/xres_git/lib/classlib/RoomTypeFilter/Mapper.php)
- [lib/classlib/RoomTypeFilter.php](/home/d.shein/Projects/xres_git/lib/classlib/RoomTypeFilter.php)

Из анализа текущих файлов видно:

- это не CRUD для computed `rpac_filters`
- это отдельный policy слой, который ограничивает room types по `external_hotel_code`, pax/adults/children и operator scope
- filter применяется как правило/коллекция правил, а не как ручное редактирование build result

Значит:

- `RoomTypeFilter` нельзя путать с `rpac_filters`
- если его поведение нужно сохранить в greenfield, его надо моделировать как отдельный policy surface
- если его поведение заменяется новым `OccupancyOverridePolicy`, это должно быть отдельным архитектурным решением

### 2. Какие Формы Нужны Для Greenfield-Архитектуры

Ниже только те формы, которые действительно нужны для ручного ввода или изменения business rules.

### 2.0. Форма `Hotel Matching / External Code`

Статус:

- уже существует в legacy admin surfaces
- должна рассматриваться как обязательный upstream admin source

Назначение:

- управлять `external_code`
- управлять exportability/status гостиницы
- быть master source для OTDS hotel identity

Текущие UI-источники:

- [modules/xadmin/application/modules/zhotels/forms/Overview.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/zhotels/forms/Overview.php)
- [modules/xadmin/application/modules/zhotels/controllers/HotelsController.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/zhotels/controllers/HotelsController.php)

Ключевые поля, влияющие на `Synxis -> RPAC -> OTDS`:

- `provider`
- `hotel_code`
- `external_code`
- `export`
- `status`
- `operator_id`
- `source_market_id`

Почему форма обязательна:

- OTDS export selection читает `hotel_matching.external_code` напрямую
- без этой сущности `ExportReadyHotel.external_code` неоткуда брать как master identity
- это upstream hotel master/matching surface, а не downstream export policy

### 2.1. Форма `Synxis RatePlan -> MealPlan Mapping`

Статус:

- уже существует
- должна быть сохранена

Назначение:

- администрировать mapping `rate_plan_code -> board_code/meal_plan`
- быть source of truth для canonical/build слоёв

Текущий UI-источник:

- [modules/xadmin/classes/Hotel/SynxisContractDetails/Forms/AbstractForm.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/SynxisContractDetails/Forms/AbstractForm.php)

Поля формы:

- `synxis_hotel_id`
  - required
  - integer
  - `> 0`
- `environment`
  - required
  - select
  - допустимые значения сейчас: `CCRS`, `ECRS`, `UCRS`
- `hotel_name`
  - read-only
  - display-only
  - вычисляется по `synxis_hotel_id + environment`
- `rate_code`
  - required
  - string
  - max length `40`
- `meal_plan`
  - required
  - select
  - options зависят от environment

Уникальность:

- `synxis_hotel_id + environment + rate_code`

Почему форма нужна:

- в текущем legacy уже нет автоматического безопасного вывода `board_code` без внешнего mapping
- greenfield-spec прямо фиксирует `provider_rateplan_board_mapping` как обязательную таблицу
- это ручной бизнес-справочник, а не вычисляемый pipeline artifact

Рекомендация по эволюции без поломки:

- не переименовывать текущую форму
- в новом доменном слое трактовать `meal_plan` как `board_code`
- при необходимости добавить read-only поле `hotel_code`, но не заменять существующий `synxis_hotel_id`

### 2.2. Форма `OTDS Hotel Export Policy`

Статус:

- уже существует
- должна быть сохранена

Текущий UI-источник:

- [modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Forms/AbstractForm.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Forms/AbstractForm.php)
- [modules/xadmin/application/modules/export/controllers/SeasonsHotelOtdsController.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/export/controllers/SeasonsHotelOtdsController.php)

Поля формы:

- `external_hotel_code`
  - required
  - uppercase string
  - regex: `^[A-Z]{3}[A-Z0-9]{1,5}$`
- `offers_start_min_days`
  - optional
  - integer
  - `> 0`
- `offers_start_max_days`
  - optional
  - integer
  - `> 0`
- `season_date_min`
  - optional
  - date
- `season_date_max`
  - optional
  - date
- `adults_max`
  - optional
  - integer
  - `> 0`
- `children_max`
  - optional
  - integer
  - `>= 0`
- `travel_durations`
  - required
  - comma-separated integer list
- `travel_type`
  - required
  - multiselect
  - currently:
    - `HOTEL_ONLY`
    - `DATA_MIX`
- `operator_id`
  - optional
  - select

Валидации:

- `offers_start_min_days < offers_start_max_days`
- `season_date_min <= season_date_max`
- уникальная комбинация policy не должна дублироваться

Почему форма нужна:

- она задаёт business filters для OTDS export
- это downstream policy, а не часть raw SynXis import
- форма уже встроена в текущий operational process
- поле `external_hotel_code` в этой форме не должно трактоваться как место, где рождается hotel identity

### 2.3. Новая Форма `Provider Room Mapping`

Статус:

- в текущем коде явного CRUD не найдено
- форма должна быть добавлена

Связь со spec:

- соответствует таблице `provider_room_mapping`
- нужна для `RPAC -> OTDS mapping layer`

Поля формы:

- `provider`
  - required
  - default `synxis`
  - лучше read-only
- `environment`
  - optional
  - добавлять только если room mapping реально environment-specific
- `hotel_code`
  - required
  - string
- `provider_room_code`
  - required
  - string
- `provider_room_code_canonical`
  - required
  - string
  - default: `provider_room_code + hotel_code`
- `booking_code`
  - required
  - string
- `room_type`
  - required
  - string или select
- `room_name`
  - required
  - string
- `active`
  - optional
  - boolean
- `comment`
  - optional
  - text
- `valid_from`
  - optional
  - date
- `valid_to`
  - optional
  - date

Уникальность:

- `provider + hotel_code + provider_room_code_canonical`

Валидации:

- `provider_room_code` не пустой
- `provider_room_code_canonical` не пустой
- `booking_code` не пустой
- `valid_to >= valid_from`

Почему форма нужна:

- export writer не должен сам придумывать room mapping
- mapping layer требует deterministic room resolution
- отсутствие room mapping в spec уже определено как reject case

### 2.4. Новая Форма `Provider Board Mapping`

Статус:

- в текущем коде явного CRUD не найдено
- форма должна быть добавлена

Связь со spec:

- соответствует таблице `provider_board_mapping`
- нужна для export-ready board resolution

Поля формы:

- `provider`
  - required
  - default `synxis`
  - read-only
- `provider_board_code`
  - required
  - string
- `booking_code`
  - required
  - string
- `board_type`
  - required
  - string или select
- `board_name`
  - required
  - string
- `active`
  - optional
  - boolean
- `comment`
  - optional
  - text

Уникальность:

- `provider + provider_board_code`

Почему форма нужна:

- `meal_plan` из SynXis ещё не равен автоматически OTDS export representation
- mapping layer должен иметь административный source of truth
- отсутствие board mapping уже является reject-сценарием в spec

### 2.5. Legacy-Adjacent Форма `Room Type Filter`

Статус:

- уже существует в legacy
- не является core mapping form
- требует явного решения: сохранить или заменить

Текущий UI-источник:

- [modules/xadmin/application/modules/export/forms/Roomtypefilter.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/export/forms/Roomtypefilter.php)
- [modules/xadmin/application/modules/export/controllers/RoomtypefilterController.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/export/controllers/RoomtypefilterController.php)

Поля формы:

- `room_type_code`
- `external_hotel_code`
- `operator_id`
- `pax_from`
- `pax_to`
- `adult_from`
- `adult_to`
- `children_from`
- `children_to`

Что важно:

- это policy form
- это не редактирование `rpac_filters`
- эта форма исторически управляет ограничением export/cache поведения по occupancy-like правилам

Решение для greenfield:

- либо сохранить как отдельный `Export Room Type Policy`
- либо поглотить в новый `OccupancyOverridePolicy`

Пока решение не принято, эту форму нельзя просто вычеркнуть из admin surface analysis

### 3. Какие Экраны Должны Быть Только Read-Only

Ниже сущности, которые нельзя делать ручным CRUD, иначе ломается основная идея deterministic pipeline.

### 3.1. Экран `Synxis Bundle Browser`

Источник данных:

- greenfield table `synxis_hotel_bundle`

Назначение:

- наблюдать входной bundle
- видеть validation state
- открывать raw XML

Колонки:

- `id`
- `provider`
- `environment`
- `hotel_code`
- `downloaded_at`
- `validation_status`
- `checksum`
- `rates present`
- `inventory present`
- `availabilities present`
- `descriptive present`

Действия:

- `view xml`
- `revalidate`
- `rebuild HotelData`

Почему не edit form:

- bundle должен быть immutable snapshot внешнего источника
- ручная правка raw XML разрушает repeatability pipeline

### 3.2. Экран `RPAC Build Browser`

Источник данных:

- `rpac_hotels`
- `rpac_offers`
- `rpac_intersections`

Назначение:

- видеть результат build-а
- понимать, почему hotel built/rejected

Колонки:

- `rpac_hotel_id`
- `hotel_code`
- `version`
- `status`
- `currency`
- `bundle_id`
- `offers_count`
- `intersections_count`
- `warnings_count`
- `rejects_count`
- `created_at`

Действия:

- `rebuild from bundle`
- `open warnings/rejects`
- `open export preview`

Почему не edit form:

- `RPAC` должен вычисляться из `HotelData`, а не редактироваться пользователем
- ручной edit `intersections/prices/availabilities` приведёт к расхождению с входным bundle

### 3.3. Экран `Warnings / Rejects Viewer`

Назначение:

- показывать machine-readable причины отбраковки
- служить operational troubleshooting surface

Колонки:

- `hotel_code`
- `rpac_version`
- `level`
- `code`
- `message`
- `entity_type`
- `entity_key`
- `payload_json`
- `created_at`

Почему нужен:

- в spec уже есть `BuildReject`, `BuildWarning` и error taxonomy
- без этого экранa оператор не сможет понять, чего именно не хватает: mapping, occupancy, price или descriptive room

### 3.4. Экран `OTDS Export Browser`

Назначение:

- наблюдать финальный export artifact
- скачивать XML/archives
- выполнять re-export

Колонки:

- `hotel_code`
- `external_code`
- `destination`
- `rpac_version`
- `export_status`
- `xml_path`
- `archive_path`
- `created_at`
- `export_error_code`

Действия:

- `download xml`
- `download archive`
- `re-export`

Почему не edit form:

- writer должен сериализовать уже готовую модель
- редактирование итогового XML руками ломает boundary между mapping и export layers

### 4. Какие Формы Не Нужно Делать

Нельзя проектировать пользовательские editable формы для:

- `synxis_hotel_bundle` raw payload
- `HotelData`
- `rpac_offers`
- `rpac_intersections`
- `rpac_prices`
- `rpac_availabilities`
- `rpac_filters`
- final OTDS XML contents

Причина:

- все эти сущности являются либо snapshot-ами внешних данных, либо детерминированно вычисляемыми доменными артефактами
- ручное редактирование приведёт к потере воспроизводимости
- это противоречит текущей greenfield-цели: pipeline должен быть stable, layered и replayable

### 5. Рекомендуемая Очерёдность Реализации UI

P0:

1. сохранить текущий CRUD `SynxisContractDetails`
2. сохранить текущий CRUD `ExportSeasonsHotelOtds`
3. добавить CRUD `Provider Room Mapping`
4. добавить CRUD `Provider Board Mapping`

P1:

1. добавить `Synxis Bundle Browser`
2. добавить `RPAC Build Browser`
3. добавить `Warnings / Rejects Viewer`
4. добавить `OTDS Export Browser`

### 6. Итоговый Минимальный Admin Surface

Write forms:

- `Hotel Matching / External Code`
- `Synxis RatePlan -> MealPlan Mapping`
- `OTDS Hotel Export Policy`
- `Provider Room Mapping`
- `Provider Board Mapping`

Conditional legacy policy forms:

- `Room Type Filter` if legacy export/cache behaviour must be preserved

Read-only screens:

- `Synxis Bundle Browser`
- `RPAC Build Browser`
- `Warnings / Rejects Viewer`
- `OTDS Export Browser`

Это минимальный набор, который:

- опирается на уже существующие admin-модули
- покрывает все реально ручные business inputs
- не смешивает ручное администрирование с вычисляемыми pipeline artifacts
- не противоречит `SYNXIS_RPAC_OTDS_GREENFIELD_SPEC.md`

### 7.0. `Hotel Matching / External Code`

Текущие связанные файлы:

- [modules/otds/src/Hotels/HotelsSelector.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/HotelsSelector.php)
- [modules/otds/src/Hotels/HotelCandidate.php](/home/d.shein/Projects/xres_git/modules/otds/src/Hotels/HotelCandidate.php)
- [modules/xadmin/application/modules/zhotels/forms/Overview.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/zhotels/forms/Overview.php)
- [modules/xadmin/classes/Hotel/Db/TableRelations/HotelMatching.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/Db/TableRelations/HotelMatching.php)

| UI field | Current DB column | Greenfield entity/field | Meaning | Used in pipeline step | Editable by | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `provider` | `hotel_matching.provider` | `HotelMaster.provider` | provider namespace | Export selection | business ops / matching team | part of matching identity |
| `hotel_code` | `hotel_matching.hotel_code` | `HotelMaster.hotel_code` | provider hotel identifier | Export selection, RPAC lookup | business ops / matching team | part of matching identity |
| `external_code` | `hotel_matching.external_code` | `ExportReadyHotel.external_code` master source | OTDS accommodation identity | HotelsSelector, Mapping, Export | business ops / matching team | primary source of truth |
| `export` | `hotel_matching.export` | exportability flags | hotel export eligibility | HotelsSelector | business ops / matching team | product type gating |
| `status` | `hotel_matching.status` | hotel export state | hotel export eligibility | HotelsSelector | business ops / matching team | must be in exportable statuses |
| `operator_id` | `hotel_matching.operator_id` | operator scope | export config matching | HotelsSelector | business ops / matching team | affects export selection |
| `source_market_id` | `hotel_matching.source_market_id` | source market scope | export config matching | HotelsSelector | business ops / matching team | affects export selection |

Pipeline impact:

1. hotel matching defines whether hotel is exportable at all
2. `HotelsSelector` reads `external_code` from `hotel_matching`
3. `HotelCandidate` cannot exist without non-empty `external_code`
4. downstream policies use this `external_code` as lookup key

### 7. UI / DB / Domain / Pipeline Matrix

Ниже зафиксирована практическая матрица, которая связывает:

- admin field
- persistence column
- domain meaning
- pipeline usage
- ownership

Это нужно, чтобы:

- не проектировать формы в отрыве от реального data flow
- не смешивать operational UI и domain model
- не потерять совместимость с существующим legacy admin

### 7.1. `Synxis RatePlan -> MealPlan Mapping`

Текущие связанные файлы:

- [modules/xadmin/classes/Hotel/SynxisContractDetails/Forms/AbstractForm.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/SynxisContractDetails/Forms/AbstractForm.php)
- [lib/classlib/Db/Hotel/Tables/SynxisContractDetails.php](/home/d.shein/Projects/xres_git/lib/classlib/Db/Hotel/Tables/SynxisContractDetails.php)
- [lib/classlib/Hotel/SynXis/DataProvider/ContractDetails.php](/home/d.shein/Projects/xres_git/lib/classlib/Hotel/SynXis/DataProvider/ContractDetails.php)

| UI field | Current DB column | Greenfield entity/field | Meaning | Used in pipeline step | Editable by | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `synxis_hotel_id` | `synxis_contract_details.synxis_id` | `provider_rateplan_board_mapping.hotel_code` surrogate selector | указывает отель SynXis, для которого действует mapping | Canonical Layer, board resolution | business ops | в legacy это integer id, в greenfield не нужно ломать UI; можно резолвить в `hotel_code` downstream |
| `environment` | `synxis_contract_details.environment` | `provider_rateplan_board_mapping.environment` | разделяет mapping по environment | Input/Canonical Layer | business ops | значения уже ограничены `CCRS/ECRS/UCRS` |
| `hotel_name` | не хранится, display-only | derived display field | человекочитаемое имя отеля | не используется прямо | nobody | только для UI |
| `rate_code` | `synxis_contract_details.rate_code` | `provider_rateplan_board_mapping.rate_plan_code` | provider rate plan code | Canonical Layer, Build Layer | business ops | обязательный source key |
| `meal_plan` | `synxis_contract_details.meal_plan` | `provider_rateplan_board_mapping.board_code` | board/meal identity для rate plan | Canonical Layer, Build Layer | business ops | в legacy имя поля `meal_plan`, в greenfield доменно это `board_code` |

Pipeline impact:

1. bundle parsed
2. из rates берётся `rate_plan_code`
3. mapping lookup ищет `hotel + environment + rate_plan_code`
4. результат становится `board_code`
5. без записи build не должен silently invent-ить board

### 7.2. `OTDS Hotel Export Policy`

Текущие связанные файлы:

- [modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Forms/AbstractForm.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Forms/AbstractForm.php)
- [modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Db/SeasonsHotelOtds.php](/home/d.shein/Projects/xres_git/modules/xadmin/classes/Hotel/ExportSeasonsHotelOtds/Db/SeasonsHotelOtds.php)
- [lib/classlib/Db/Hotel/Tables/ExportSeasonsHotelOtds.php](/home/d.shein/Projects/xres_git/lib/classlib/Db/Hotel/Tables/ExportSeasonsHotelOtds.php)

| UI field | Current DB column | Greenfield entity/field | Meaning | Used in pipeline step | Editable by | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `external_hotel_code` | `export_seasons_hotel_otds.external_hotel_code` | `ExportPolicy.external_hotel_code` lookup key | key used to attach policy to hotel | Export eligibility | business ops | должен ссылаться на `hotel_matching.external_code`, а не заменять его |
| `offers_start_min_days` | `export_seasons_hotel_otds.offers_start_min_days` | `ExportParams.offers_start_min_days` | минимальный booking lead time | Export eligibility | business ops | optional filter |
| `offers_start_max_days` | `export_seasons_hotel_otds.offers_start_max_days` | `ExportParams.offers_start_max_days` | максимальный booking lead time | Export eligibility | business ops | optional filter |
| `season_date_min` | `export_seasons_hotel_otds.season_date_min` | `ExportParams.season_date_min` | нижняя граница travel season | Export eligibility | business ops | optional filter |
| `season_date_max` | `export_seasons_hotel_otds.season_date_max` | `ExportParams.season_date_max` | верхняя граница travel season | Export eligibility | business ops | optional filter |
| `adults_max` | `export_seasons_hotel_otds.adults_max` | `ExportParams.adults_max` | ограничение по adult occupancy | Export filtering | business ops | optional |
| `children_max` | `export_seasons_hotel_otds.children_max` | `ExportParams.children_max` | ограничение по child occupancy | Export filtering | business ops | optional |
| `travel_durations` | `export_seasons_hotel_otds.travel_durations` | `ExportParams.travel_durations` | допустимые durations | Export filtering | business ops | required CSV in legacy |
| `travel_type` | `export_seasons_hotel_otds.travel_type` | `ExportParams.travel_type` | какие типы offer экспортировать | Export filtering | business ops | multiselect |
| `operator_id` | `export_seasons_hotel_otds.operator_id` | `ExportParams.operator_scope` | ограничение по operator | Export routing/filtering | business ops | optional |

Pipeline impact:

1. `RPAC` уже построен
2. hotel уже имеет `external_code` из hotel matching
3. export policy lookup ищет правила по `external_hotel_code`
4. найденная policy фильтрует travel windows/durations/operator scope
5. writer сериализует только уже разрешённые combinations

### 7.3. `Provider Room Mapping`

Greenfield table:

- `provider_room_mapping`

Текущий прямой CRUD в legacy не найден.

| UI field | Target DB column | Domain field | Meaning | Used in pipeline step | Editable by | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `provider` | `provider_room_mapping.provider` | `MappedRoom.provider` | provider namespace | Mapping Layer | business ops | default `synxis` |
| `environment` | `provider_room_mapping.environment` if introduced | optional scope | env-specific room mapping | Mapping Layer | business ops | добавлять только при реальной необходимости |
| `hotel_code` | `provider_room_mapping.hotel_code` | room mapping scope | ограничивает mapping отелем | Mapping Layer | business ops | required |
| `provider_room_code` | `provider_room_mapping.provider_room_code` | source room code | raw SynXis room code | Canonical/Mapping Layer | business ops | required |
| `provider_room_code_canonical` | `provider_room_mapping.provider_room_code_canonical` | canonical room identity | canonicalized room code | Build Layer, Mapping Layer | business ops | default from policy |
| `booking_code` | `provider_room_mapping.booking_code` | `MappedRoom.booking_code` | OTDS/export room code | Export Layer | business ops | required |
| `room_type` | `provider_room_mapping.room_type` | `MappedRoom.otds_type` | room classification | Export Layer | business ops | required |
| `room_name` | `provider_room_mapping.room_name` | `MappedRoom.name` | human-readable name | Export Layer | business ops | required |
| `active` | `provider_room_mapping.active` if introduced | lifecycle flag | soft disable mapping | Mapping Layer | business ops | recommended |
| `comment` | `provider_room_mapping.comment` if introduced | audit note | why mapping exists | operational only | business ops | recommended |
| `valid_from` | `provider_room_mapping.valid_from` if introduced | optional validity | start date | Mapping Layer | business ops | optional |
| `valid_to` | `provider_room_mapping.valid_to` if introduced | optional validity | end date | Mapping Layer | business ops | optional |

Pipeline impact:

1. build дал `room_code_canonical`
2. mapping layer ищет room mapping
3. если mapping найден, формируется `MappedRoom`
4. если mapping отсутствует, combination reject-ится
5. если после этого отель пустой, hotel reject-ится целиком

### 7.4. `Provider Board Mapping`

Greenfield table:

- `provider_board_mapping`

Текущий прямой CRUD в legacy не найден.

| UI field | Target DB column | Domain field | Meaning | Used in pipeline step | Editable by | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `provider` | `provider_board_mapping.provider` | `MappedBoard.provider` | provider namespace | Mapping Layer | business ops | default `synxis` |
| `provider_board_code` | `provider_board_mapping.provider_board_code` | source board code | upstream board/meal code | Mapping Layer | business ops | required |
| `booking_code` | `provider_board_mapping.booking_code` | `MappedBoard.booking_code` | OTDS/export board code | Export Layer | business ops | required |
| `board_type` | `provider_board_mapping.board_type` | `MappedBoard.otds_type` | board classification | Export Layer | business ops | required |
| `board_name` | `provider_board_mapping.board_name` | `MappedBoard.name` | human-readable board name | Export Layer | business ops | required |
| `active` | `provider_board_mapping.active` if introduced | lifecycle flag | soft disable mapping | Mapping Layer | business ops | recommended |
| `comment` | `provider_board_mapping.comment` if introduced | audit note | why mapping exists | operational only | business ops | recommended |

Pipeline impact:

1. canonical/build слои уже определили `board_code`
2. mapping layer ищет board mapping
3. если mapping найден, формируется `MappedBoard`
4. если mapping отсутствует, combination reject-ится

### 7.5. `Synxis Bundle Browser`

Greenfield table:

- `synxis_hotel_bundle`

| UI column/action | DB field | Domain meaning | Pipeline step | Editable by | Notes |
| --- | --- | --- | --- | --- | --- |
| `provider` | `provider` | provider namespace | Input Layer | nobody | read-only |
| `environment` | `environment` | source environment | Input Layer | nobody | read-only |
| `hotel_code` | `hotel_code` | hotel identity | Input Layer | nobody | read-only |
| `downloaded_at` | `downloaded_at` or `created_at` | snapshot timestamp | Input Layer | nobody | read-only |
| `validation_status` | `validation_status` or `status` | validator result | Input Validation | nobody | read-only |
| `checksum` | `checksum` | immutability/dedup identity | Input Layer | nobody | read-only |
| `view rates xml` | `rates_payload/path` | raw input artifact | Input Layer | nobody | action only |
| `view inventory xml` | `inventory_payload/path` | raw input artifact | Input Layer | nobody | action only |
| `view availabilities xml` | `availabilities_payload/path` | raw input artifact | Input Layer | nobody | action only |
| `view descriptive xml` | `descriptive_payload/path` | raw input artifact | Input Layer | nobody | action only |
| `revalidate` | service action | rerun validation | Input Validation | ops | service action, not direct edit |
| `rebuild HotelData` | service action | replay downstream | Canonical Layer | ops | service action |

### 7.6. `RPAC Build Browser`

Greenfield tables:

- `rpac_hotels`
- `rpac_offers`
- `rpac_intersections`
- `rpac_prices`
- `rpac_availabilities`
- `rpac_filters`

| UI column/action | DB field | Domain meaning | Pipeline step | Editable by | Notes |
| --- | --- | --- | --- | --- | --- |
| `hotel_code` | `rpac_hotels.hotel_code` | hotel identity | Build Layer | nobody | read-only |
| `version` | `rpac_hotels.version` | RPAC build version | Build Layer | nobody | read-only |
| `status` | `rpac_hotels.status` | build lifecycle state | Build/Mapping/Export | nobody | read-only |
| `currency` | `rpac_hotels.currency` | canonical currency | Canonical/Build | nobody | read-only |
| `bundle_id` | `rpac_hotels.bundle_id` | provenance | Build Layer | nobody | read-only |
| `offers_count` | derived | number of offers | Build Layer | nobody | derived metric |
| `intersections_count` | derived | number of room/board combinations | Build Layer | nobody | derived metric |
| `warnings_count` | derived | build warnings | Build Layer | nobody | derived metric |
| `rejects_count` | derived | reject count | Build Layer | nobody | derived metric |
| `rebuild from bundle` | service action | recompute RPAC | Build Layer | ops | no direct DB edit |
| `open warnings/rejects` | service action | inspect failures | Build/Mapping | ops | navigation action |
| `open export preview` | service action | inspect mapped/export-ready data | Mapping/Export | ops | navigation action |

### 7.7. `Warnings / Rejects Viewer`

Recommended greenfield persistence:

- отдельная таблица событий или materialized view по `BuildWarning`, `BuildReject`, export errors

| UI column | Domain field | Meaning | Editable by | Notes |
| --- | --- | --- | --- | --- |
| `hotel_code` | `hotel_code` | hotel scope | nobody | read-only |
| `rpac_version` | `version` | build version | nobody | read-only |
| `level` | `warning/reject/error` | severity | nobody | read-only |
| `code` | `error_code` | machine-readable identifier | nobody | must match taxonomy |
| `message` | `message` | human-readable explanation | nobody | localized if needed |
| `entity_type` | `entity_type` | hotel/offer/intersection/room/board | nobody | diagnostic |
| `entity_key` | `entity_key` | concrete entity id | nobody | diagnostic |
| `payload_json` | `payload_json` | structured debug context | nobody | diagnostic |
| `created_at` | `created_at` | timestamp | nobody | diagnostic |

### 7.8. `OTDS Export Browser`

Recommended greenfield persistence:

- export run table or artifact registry

| UI column/action | Domain field | Meaning | Pipeline step | Editable by | Notes |
| --- | --- | --- | --- | --- | --- |
| `hotel_code` | `hotel_code` | hotel identity | Export Layer | nobody | read-only |
| `external_code` | `external_code` | OTDS export identity | Mapping/Export | nobody | read-only |
| `destination` | `destination` | export destination | Export Layer | nobody | read-only |
| `rpac_version` | `rpac_version` | provenance | Export Layer | nobody | read-only |
| `export_status` | `status` | export lifecycle | Export Layer | nobody | read-only |
| `xml_path` | `xml_path` | generated xml artifact | Export Layer | nobody | read-only |
| `archive_path` | `archive_path` | packaged artifact | Export Layer | nobody | read-only |
| `created_at` | `created_at` | export timestamp | Export Layer | nobody | read-only |
| `export_error_code` | `error_code` | machine-readable export failure | Export Layer | nobody | read-only |
| `download xml` | service action | fetch generated file | Export Layer | ops | action only |
| `download archive` | service action | fetch generated archive | Export Layer | ops | action only |
| `re-export` | service action | rerun export on existing RPAC | Export Layer | ops | service action |

### 7.9. `Room Type Filter`

Текущие связанные файлы:

- [modules/xadmin/application/modules/export/forms/Roomtypefilter.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/export/forms/Roomtypefilter.php)
- [modules/xadmin/application/modules/export/controllers/RoomtypefilterController.php](/home/d.shein/Projects/xres_git/modules/xadmin/application/modules/export/controllers/RoomtypefilterController.php)
- [lib/classlib/Model/Export/RoomTypeFilter.php](/home/d.shein/Projects/xres_git/lib/classlib/Model/Export/RoomTypeFilter.php)
- [lib/classlib/RoomTypeFilter/Mapper.php](/home/d.shein/Projects/xres_git/lib/classlib/RoomTypeFilter/Mapper.php)

| UI field | Current DB column | Domain field | Meaning | Used in pipeline step | Editable by | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `room_type_code` | `infxCacheRoomTypeFilter.room_type_code` | `ExportRoomTypePolicy.room_type_code` | room type selector/prefix | legacy cache/export filtering | business ops | policy field |
| `external_hotel_code` | `infxCacheRoomTypeFilter.external_hotel_code` | `ExportRoomTypePolicy.external_hotel_code` | hotel scope | legacy cache/export filtering | business ops | lookup key |
| `operator_id` | `infxCacheRoomTypeFilter.operator_id` | `ExportRoomTypePolicy.operator_id` | operator scope | legacy cache/export filtering | business ops | optional |
| `pax_from` | `infxCacheRoomTypeFilter.pax_from` | `ExportRoomTypePolicy.pax_from` | min pax | legacy cache/export filtering | business ops | policy field |
| `pax_to` | `infxCacheRoomTypeFilter.pax_to` | `ExportRoomTypePolicy.pax_to` | max pax | legacy cache/export filtering | business ops | policy field |
| `adult_from` | `infxCacheRoomTypeFilter.adult_from` | `ExportRoomTypePolicy.adult_from` | min adults | legacy cache/export filtering | business ops | policy field |
| `adult_to` | `infxCacheRoomTypeFilter.adult_to` | `ExportRoomTypePolicy.adult_to` | max adults | legacy cache/export filtering | business ops | policy field |
| `children_from` | `infxCacheRoomTypeFilter.children_from` | `ExportRoomTypePolicy.children_from` | min children | legacy cache/export filtering | business ops | policy field |
| `children_to` | `infxCacheRoomTypeFilter.children_to` | `ExportRoomTypePolicy.children_to` | max children | legacy cache/export filtering | business ops | policy field |

Interpretation:

- это редактируемая policy table
- это не то же самое, что `rpac_filters`
- если feature нужна в greenfield, она должна жить рядом с export policies, а не внутри computed RPAC persistence

### 8. Ownership Matrix

Чтобы не было размывания ответственности, ownership должен быть явным.

| Surface | Owner | Why |
| --- | --- | --- |
| `Hotel Matching / External Code` | business ops / hotel matching team | это master identity и exportability surface |
| `Synxis RatePlan -> MealPlan Mapping` | business ops / hotel standing data team | это business mapping, а не технический артефакт |
| `OTDS Hotel Export Policy` | business ops / export configuration team | это downstream commercial/export policy |
| `Provider Room Mapping` | business ops / content mapping team | требует ручной семантической привязки room identities |
| `Provider Board Mapping` | business ops / content mapping team | требует ручной семантической привязки board identities |
| `Room Type Filter` | business ops / export policy team | это policy surface, а не computed artifact |
| `Synxis Bundle Browser` | operations / support | это operational observability surface |
| `RPAC Build Browser` | operations / engineering support | это diagnostic surface |
| `Warnings / Rejects Viewer` | operations / engineering support | это troubleshooting surface |
| `OTDS Export Browser` | operations / export support | это artifact monitoring surface |

### 9. UI Design Constraints

Чтобы не ломать текущие legacy-паттерны, новые формы должны следовать тем же принципам, что уже есть в `xadmin`.

Правила:

- `hotel_matching.external_code` считается master source для OTDS hotel identity
- для mappings использовать отдельные CRUD screens, как сейчас сделано для `SynxisContractDetails`
- для export policy сохранять отдельный screen и mass edit, как сейчас сделано для `ExportSeasonsHotelOtds`
- `ExportSeasonsHotelOtds.external_hotel_code` трактовать как lookup key на hotel matching, а не как источник identity
- `RoomTypeFilter`, если сохраняется, держать как отдельный policy screen
- для read-only pipeline artifacts использовать datagrid/browser-style pages
- не смешивать editable policy fields и computed pipeline fields на одном экране редактирования
- все destructive actions делать как explicit service actions, а не как inline field edits

### 10. Минимальный UI Definition Of Done

Admin UI для `Synxis -> RPAC -> OTDS` считается достаточным только если:

1. существующий `SynxisContractDetails` сохранён и трактуется как `rate_plan -> board`
2. `hotel_matching.external_code` явно признан master source для OTDS identity
3. существующий `ExportSeasonsHotelOtds` сохранён как OTDS export policy
4. есть новый CRUD для room mappings
5. есть новый CRUD для board mappings
6. принято явное решение по `RoomTypeFilter`: сохранить или поглотить
7. есть read-only browser для bundle snapshots
8. есть read-only browser для RPAC builds
9. есть read-only browser для warnings/rejects
10. есть read-only browser для export artifacts
11. ни один computed artifact не редактируется руками
12. у каждой формы есть явный owner, unique key и pipeline usage contract

## Новая Задача

### Задача 11.1. Описать greenfield-модель `Synxis -> RPAC -> OTDS`

Нужно зафиксировать:

- какие сущности являются обязательными
- какие таблицы являются минимально необходимыми
- что хранится в `SynxisHotelBundle`
- что хранится в `HotelData`
- что хранится в `RPAC`
- какие mappings обязательны для `OTDS export`
- какие identity rules обязательны для `Synxis`

Артефакт:

- отдельная greenfield specification для `Synxis -> RPAC -> OTDS`

Результат задачи:

- понятная целевая архитектура, из которой уже можно отдельно проектировать input layer, build layer, persistence layer и export layer
