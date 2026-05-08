# Sprint 1 - Task 0.7

## Зафиксировать taxonomy ошибок и reject-сценариев

## Цель

Разделить и нормализовать:

- transport errors
- validation errors
- business rejects
- warnings
- technical failures

## Error families

### 1. Transport errors

Примеры:

- `transport_timeout`
- `transport_fault`
- `transport_auth_failed`

### 2. Bundle validation errors

Примеры:

- `bundle_missing_required_document`
- `bundle_empty_document`
- `bundle_invalid_xml`
- `bundle_hotel_code_mismatch`

### 3. Canonicalization errors

Примеры:

- `canonical_multi_currency`
- `canonical_child_policy_unresolved`
- `canonical_room_data_inconsistent`

### 4. Build rejects

Примеры:

- `reject_room_unmapped`
- `reject_board_unmapped`
- `reject_rateplan_without_intersections`
- `reject_intersection_removed_by_occupancy`
- `reject_hotel_empty_after_filters`

### 5. Export rejects

Примеры:

- `reject_missing_external_code`
- `reject_room_not_exportable`
- `reject_board_not_exportable`

### 6. Warnings

Примеры:

- `warn_age_semantics_approximated`
- `warn_unknown_optional_payload`
- `warn_non_blocking_mapping_gap`

## Scope model

Каждый code должен иметь scope:

- `bundle`
- `hotel`
- `offer`
- `intersection`
- `room`
- `board`

## Retryability matrix

### Retryable

- transport timeout
- transient network fault
- temporary external system failure

### Non-retryable deterministic rejects

- room unmapped
- board unmapped
- missing external_code
- invalid bundle completeness

## Severity model

- `error`
- `warning`
- `reject`

`reject` означает детерминированную бизнес-невозможность продолжать конкретный scope.

## Что это разблокирует

После `0.7` можно:

- проектировать warning/reject storage
- писать bundle validator
- писать build aggregator
- делать observability surfaces

