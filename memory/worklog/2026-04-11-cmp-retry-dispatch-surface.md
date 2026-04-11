# 2026-04-11 CMP Retry Dispatch Surface

## Why

The CMP/TAP refactor had already gained host-neutral session, project, flow, control, peer-approval, TAP status, and TAP history surfaces, but it still lacked one recoverable runtime path after TAP or control blocked a dispatch. Callers could request approval and release gates, yet they still had to reconstruct the original dispatch input themselves if they wanted to resume delivery.

## What Changed

- Added a host-neutral `retryCmpDispatch` surface to `PraxisRuntimeUseCases`, `PraxisRuntimeFacades`, and `PraxisRuntimeInterface`.
- The retry path now rebuilds dispatch input from persisted `cmpContextPackage` truth instead of requiring the caller to retain the full original `contextPackage`.
- `dispatchCmpFlow` now persists stable retry metadata onto stored package descriptors:
  - `dispatch_target_kind`
  - `dispatch_reason`
  - `dispatch_attempt_count`
  - `last_dispatch_status`
  - `last_dispatch_topic`
  - `last_dispatch_updated_at`
  - `blocked_by_tap_gate`
- Added TAP runtime audit event `dispatch_retry_requested`.
- Added stable runtime-interface error codes:
  - `cmp_package_not_found`
  - `cmp_dispatch_not_retryable`

## Boundary Notes

- The new recovery lane stays host-neutral and does not route through CLI or GUI contracts.
- Retry uses existing host-backed package truth and re-enters the same dispatch use case instead of creating a second recovery-specific delivery engine.
- The surface is intentionally scoped to replaying previously attempted dispatches, not to materializing fresh packages.

## Verification

- Added host-runtime facade coverage for blocked dispatch -> control release -> retry replay.
- Added runtime-interface coverage for codec, stable error envelopes, and blocked dispatch -> retry flow.
- `swift test` passed on `2026-04-11` with `145` tests across `39` suites.
