# 2026-04-13 Slice 3 FFI boundary regression hardening

## Context

- Scope stayed inside `PraxisFFI`, `PraxisRuntimeInterface`, and `PraxisHostRuntimeArchitectureTests`.
- Goal was to harden the existing encoded bridge contract without widening the host layer or freezing a larger ABI.

## What changed

- Added FFI regression coverage for runtime session closure idempotency:
  - closing a live handle returns `true`
  - closing the same handle again returns `false`
  - closing an unknown handle returns `false`
- Added FFI regression coverage for event-buffer monotonicity:
  - `snapshotEncodedEvents` does not clear the buffer
  - `drainEncodedEvents` returns the buffered events and clears them
  - a post-drain snapshot is empty
- Added FFI regression coverage for per-handle event isolation:
  - one handle's buffered events do not leak into another handle
  - independent handles retain their own session-scoped event identities
- Tightened FFI-side failure assertions so `decode failure` and `session_not_found` envelopes are checked for stable `code`, `message`, and `retryable` semantics.
- Added a runtime interface codec regression that keeps legacy flat decoding explicitly limited to `runGoal` and `resumeRun`.
- Added a boundary comment in `PraxisRuntimeInterfaceRequest` decoding to document that narrow legacy-flat compatibility policy.

## Validation

- `swift test --filter HostRuntimeSurfaceTests`
- `swift test --filter HostRuntimeInterfaceTests`
- `swift test`

## Result

- The existing implementation already satisfied the new Slice 3 regressions.
- No new public API was introduced.
- `PraxisFFI` remains a thin encoded bridge over `PraxisRuntimeInterfaceRegistry`.

## Residual

- This slice still does not freeze a larger multi-language ABI or streaming protocol.
- The legacy flat compatibility path remains intentionally narrow and test-guarded rather than generalized.
