# 2026-04-13 Slice 1 MP Provider-Unavailable Truth Hardening

## What Changed

- Tightened the `provider inference == unavailable` wording in `PraxisMpHostInspectionService`.
- Removed the stronger fallback claim that MP `remains local-baseline only` when no provider inference surface is registered.
- Unified the unavailable wording through one private helper so smoke and inspection cannot drift apart again.
- Added regression coverage for mixed provenance combinations where:
  - provider inference is unavailable
  - browser grounding stays present under `scaffoldPlaceholder`, `localBaseline`, or `composed`
  - audio and speech lanes use a mixed baseline/composed combination

## Why This Package Exists

- Slice 1 no longer had a large HostRuntime truth bug.
- The remaining credible risk was smaller but still real: the unavailable provider-inference branch was making a stronger inference than the runtime could actually prove.
- If the runtime only knows that the provider inference lane is absent, it should not also imply that the rest of MP is definitively `local-baseline only`.
- This package narrows that claim and adds regression coverage so future wording changes do not quietly reintroduce the stronger statement.

## Files Touched

- `Sources/PraxisRuntimeUseCases/PraxisMpHostInspection.swift`
- `Tests/PraxisRuntimeUseCasesTests/PraxisRuntimeUseCasesTests.swift`

## Validation

- `swift test --filter PraxisRuntimeUseCasesTests`
- `swift test`

Current local snapshot after this package:

- `371` tests
- `53` suites

## Residual Notes

- This package intentionally stays inside the MP host inspection/smoke surface.
- It does not attempt a repository-wide wording sweep for CMP/TAP readbacks.
- Facade/interface summary compression remains acceptable for this slice, but deeper cross-layer provenance regression can still be expanded in later slices if needed.
