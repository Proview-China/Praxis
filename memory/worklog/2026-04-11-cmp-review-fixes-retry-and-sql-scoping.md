# 2026-04-11 CMP Review Fixes: Retry and SQL Scoping

## Confirmed Issues

The following review findings were confirmed against the current Swift implementation:

- `retryCmpDispatch` incorrectly treated already dispatched packages as retryable.
- Local SQLite TAP event reads applied the per-project `LIMIT` before agent/target filtering.
- Local SQLite peer-approval reads applied the 200-row cap before agent/target/capability filtering.
- CMP peer-approval persistence stored the original `capabilityKey` string even after runtime normalization trimmed it for validation and routing.

## Fixes

- Tightened `retryCmpDispatch` so it only accepts packages that remain `materialized`, were explicitly blocked by TAP, and carry `last_dispatch_status == rejected`.
- Pushed peer-approval query predicates down into SQLite SQL before `LIMIT 200`.
- Pushed TAP runtime event query predicates down into SQLite SQL before the requested limit.
- Persisted the normalized `capabilityKey` in peer-approval descriptors and used the normalized key for decision/readback lookup.

## Verification

- Added regression coverage for:
  - rejecting retries for already dispatched packages
  - scoped peer-approval reads surviving the project-wide row cap
  - scoped TAP history reads surviving unrelated newer events
  - normalized peer-approval capability keys round-tripping through request, decision, and readback
- `swift test` passed on `2026-04-11` with `149` tests across `39` suites.
