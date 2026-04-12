# 2026-04-13 Runtime Interface Opaque Reference ID Hardening

## What changed

- Introduced `PraxisRuntimeInterfaceReferenceID` in `Sources/PraxisRuntimeInterface/PraxisRuntimeInterfaceModels.swift` as a host-neutral opaque reference wrapper.
- Kept the JSON wire shape stable by encoding and decoding `PraxisRuntimeInterfaceReferenceID` as a single string value instead of an object envelope.
- Tightened the outward-facing runtime interface surface to use the typed reference wrapper for:
  - `PraxisRuntimeInterfaceSnapshot.pendingIntentID`
  - `PraxisRuntimeInterfaceEvent.intentID`
  - `PraxisRuntimeInterfaceCommitCmpFlowRequestPayload.eventIDs`
- Updated `PraxisRuntimeInterfaceServices` to validate opaque references at the boundary without canonicalizing their raw contents before passing them to existing facade/use-case commands.
- Preserved the existing commit-flow validation contract:
  - empty `eventIDs` still returns `invalid_input`
  - blank `eventIDs` elements still return `invalid_input`
- Added a narrow behavior test that feeds blank follow-up references through the run facade path and verifies the runtime interface preserves the raw opaque values instead of trimming or collapsing them to `nil`.
- Updated runtime interface and CLI tests to build and assert typed opaque reference IDs while keeping the host-neutral JSON contract stable.

## Why this stays scoped to the host-neutral interface layer

- The new type only models interface-level opaque references; it does not rename them into provider, CLI, UI, or transport-specific identifiers.
- No `Sources/PraxisRun/*`, `Sources/PraxisTransition/*`, or `Sources/PraxisState/*` internal ID models were changed.
- The service layer remains responsible for boundary validation only; downstream facades and use cases still receive the existing string payloads they already own, with opaque contents preserved exactly.

## Validation

- `swift test --filter HostRuntimeInterfaceTests`
- `swift test --filter HostRuntimeSurfaceTests`
- `swift test --filter PraxisCLITests`
- `swift test`

Current full-suite snapshot: `329 tests / 53 suites` passing.

## Residual risk

- `PraxisRuntimeInterfaceReferenceID` currently hardens only the outward-facing interface references explicitly in scope for this package; deeper run/transition/state ID domains remain string-based by design.
- Additional runtime-interface reference fields were expanded in the follow-up worklog [2026-04-13-runtime-interface-reference-surface-continuation.md](/Users/shiyu/Documents/Project/Praxis/memory/worklog/2026-04-13-runtime-interface-reference-surface-continuation.md); this note should not be read as current repo-wide coverage status for checkpoint, package, or continuation references.
