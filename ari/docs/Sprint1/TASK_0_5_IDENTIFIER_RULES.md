# Sprint 1 - Task 0.5

## Зафиксировать правила идентификаторов

Этот документ нужно читать в рамках:

- [`SYNXIS_RPAC_OTDS_GREENFIELD_SPEC.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/SYNXIS_RPAC_OTDS_GREENFIELD_SPEC.md:1)
- [`SYNXIS_RPAC_OTDS_TASKS.md`](/home/d.shein/PhpstormProjects/ked.su/ari/docs/SYNXIS_RPAC_OTDS_TASKS.md:304)

И после:

- [TASK_0_1_PROVIDER_HOTEL_BUNDLE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_1_PROVIDER_HOTEL_BUNDLE.md:1)
- [TASK_0_1_3_SYNXIS_PROVIDER_PROFILE.md](/home/d.shein/PhpstormProjects/ked.su/ari/docs/Sprint1/TASK_0_1_3_SYNXIS_PROVIDER_PROFILE.md:1)

## Почему задача критична

Без фиксированных identity rules система не сможет детерминированно:

- хранить bundle provenance
- строить mappings
- собирать offers и intersections
- поддерживать replay и versioning
- отличать raw provider identity от canonical identity и export identity

Это одна из тех задач, где ошибка на старте потом ломает половину downstream-модели.

## Общий принцип

Нужно различать несколько разных семейств идентификаторов:

1. ingestion identity
2. provider business identity
3. canonical build identity
4. export identity
5. technical record identity

Главная ошибка legacy-подходов обычно в том, что эти уровни начинают смешиваться.

## 1. Ingestion identity

### 1.1. Bundle identity

`bundle_id`

- внутренний технический UUID
- primary key bundle snapshot
- никогда не используется как business hotel identity

`bundle_checksum`

- identity входного содержимого
- используется для immutability и deduplication

Uniqueness:

```text
provider + profile + environment + hotel_code + bundle_checksum
```

### 1.2. Bundle version

`version`

- номер версии bundle внутри scope:
  - `provider`
  - `profile`
  - `environment`
  - `hotel_code`

Правило:

- новый bundle snapshot для того же отеля получает новую `version`
- старая версия не мутируется

## 2. Hotel identity

### 2.1. Provider hotel identity

`hotel_code`

- это provider hotel identifier
- он приходит из входного orchestration scope
- он участвует в:
  - bundle scope
  - canonical scope
  - RPAC scope

Правило:

- `hotel_code` не является export identity
- `hotel_code` должен быть immutable в пределах bundle и RPAC version

### 2.2. Export hotel identity

`external_code`

- это не provider hotel code
- это OTDS/export identity
- master source of truth для него должен жить в hotel matching слое

Правило:

- `hotel_code` и `external_code` не взаимозаменяемы
- `external_code` нельзя рождать в input layer
- input layer знает только provider hotel identity

## 3. Room identity

### 3.1. Provider room identity

`provider_room_code`

- raw code от provider
- приходит из source documents
- существует в provider namespace

Правило:

- на этапе parsing/canonical extraction raw code сохраняется как есть
- он нужен для traceability и mapping

### 3.2. Canonical room identity

`provider_room_code_canonical`

Для текущей модели по greenfield-spec:

```text
provider_room_code_canonical = provider_room_code + hotel_code
```

Смысл:

- raw provider room code может быть недостаточно уникальным глобально
- canonical room identity должна быть стабильной в пределах build/export lifecycle

Правило:

- canonical room code фиксируется до RPAC build
- после того как room identity canonicalized, downstream слои работают уже с canonical code

### 3.3. Freeze point для room identity

Момент фиксации неизменяемости:

- после canonical layer
- до построения `RpacIntersection`

То есть:

- parser видит raw provider code
- canonical layer вычисляет canonical room identity
- build layer уже не должен её менять

## 4. Board identity

### 4.1. Provider board identity

`provider_board_code`

- raw provider board/meal identifier
- может приходить не как прямое финальное поле для экспорта

Для Synxis важно:

- board identity в legacy не приходит как готовый export board
- она резолвится через mapping `rate plan -> board`

### 4.2. Canonical board identity

`board_code`

- это доменный board identifier, который build layer использует стабильно
- он уже должен быть результатом mapping resolution

Правило:

- build layer не должен угадывать board code на лету
- board identity должна быть resolved до offer compilation

### 4.3. Freeze point для board identity

Момент фиксации неизменяемости:

- после mapping resolution
- до построения offer identity

## 5. Rate plan identity

`rate_plan_code`

- raw provider rate plan identity
- участвует в offer identity
- должен быть стабилен в пределах `hotel_code`

Правило:

- `rate_plan_code` уникален в пределах provider hotel scope
- build layer не меняет его семантику

## 6. Offer identity

По greenfield-spec:

```text
offer = hotel_code + rate_plan_code + board_code
```

Смысл:

- offer не строится только по `rate_plan_code`
- board resolution входит в identity offer-а

Правило:

- один offer = одна комбинация hotel + rate plan + resolved board
- если board resolution невозможен, offer не должен считаться валидным

## 7. Intersection identity

`intersection`

Это sellable combination уровня:

- room
- board
- offer scope

Рекомендуемая identity:

```text
intersection = offer_id + provider_room_code_canonical
```

или эквивалентный composite key:

```text
hotel_code + rate_plan_code + board_code + provider_room_code_canonical
```

Правило:

- intersection identity не должна мутировать после того, как canonical room identity уже применена

## 8. RPAC identity

### 8.1. RPAC hotel identity

`rpac_hotels`

- scope:
  - `provider`
  - `hotel_code`
  - `version`

Правило:

- повторный build создаёт новую `version`
- старая RPAC version не переписывается

### 8.2. RPAC provenance

Каждая RPAC version должна ссылаться на:

- `bundle_id`

Это обязательная provenance link.

## 9. Export identity

Export layer должен работать с:

- `external_code`
- mapped rooms
- mapped boards
- `rpac_version`

Правило:

- export writer не должен заново резолвить provider identities
- writer получает уже стабилизированные export-ready identities

## 10. Что именно нужно признать source of truth

### Source of truth по сущностям

| Сущность | Идентификатор | Source of truth |
|---|---|---|
| bundle snapshot | `bundle_id` / `bundle_checksum` | ingestion core |
| provider hotel | `hotel_code` | input/orchestration scope |
| export hotel | `external_code` | hotel matching layer |
| provider room | `provider_room_code` | source XML |
| canonical room | `provider_room_code_canonical` | canonical/mapping policy |
| provider board | `provider_board_code` | source XML or mapping input |
| canonical board | `board_code` | mapping layer |
| offer | `hotel_code + rate_plan_code + board_code` | build layer |
| intersection | `offer + canonical room` | build layer |

## 11. Synxis-specific interpretation

Для текущего reference provider:

- provider hotel identity = `hotel_code`
- provider room identity = room code из Synxis source documents
- canonical room identity = `room_code + hotel_code`
- board identity резолвится через `provider_rateplan_board_mapping`
- offer identity = `hotel_code + rate_plan_code + board_code`

То есть Synxis не отменяет generic policy, а просто наполняет её своими concrete raw fields.

## 12. Момент фиксации неизменяемости идентификаторов

Нужно жёстко зафиксировать freeze points:

1. `bundle identity`
   - после финализации bundle
2. `provider hotel identity`
   - с момента начала orchestration bundle
3. `provider room identity`
   - с момента parsing source document
4. `canonical room identity`
   - после canonicalization
5. `board identity`
   - после mapping resolution
6. `offer identity`
   - после offer compilation
7. `intersection identity`
   - после intersection build
8. `export identity`
   - после export-ready assembly

После freeze point identity менять нельзя без новой версии соответствующей сущности.

## 13. Что нельзя делать

Нельзя:

1. трактовать `hotel_code` как export identity
2. менять canonical room code после построения intersections
3. резолвить board identity внутри XML writer
4. использовать raw provider room code как глобально уникальный без hotel scope
5. смешивать `bundle_id` и business identity

## 14. Что это разблокирует

После фиксации этих правил можно без догадок делать:

- `1.2` `provider_rateplan_board_mapping`
- `1.3` `provider_room_mapping`
- `1.4` `provider_board_mapping`
- `2.2` `ContractDetails` boundary
- `2.3` room mapping boundary
- `2.4` board mapping boundary
- `5.4` intersection builder

## Итоговая короткая формула

Нужно жёстко различать:

- raw provider identity
- canonical build identity
- export identity
- technical record identity

Именно эта граница делает pipeline устойчивым.
