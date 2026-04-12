# 2026-04-13 Presentation Bridge Event Name Alignment

## What changed

- Updated `PraxisPresentationStateMapper` in `PraxisPresentationSupport.swift` so the presentation bridge now derives `run.started`, `run.resumed`, `run.recovered`, and `run.follow_up_ready` from `PraxisRuntimeInterfaceEventName` instead of maintaining separate raw string literals.
- Kept `PraxisPresentationEvent.name` as `String` and continued emitting the same wire/output shape by using the runtime-interface enum raw values at the bridge boundary.
- Added focused presentation-bridge coverage to verify the mapper still emits the existing run event names for started, resumed, recovered, and follow-up-ready paths.

## Why this stays scoped

- The package only aligns the presentation bridge to the existing runtime-interface event-name truth source.
- It does not widen the presentation public API, change presentation titles/details, or pull CLI/UI/platform/provider semantics into the host-neutral runtime contract.
- No non-run presentation events or unrelated bridge mappings were changed.

## Validation

- `swift test --filter HostRuntimePresentationBridgeTests`
- `swift test --filter HostRuntimeSurfaceTests`

## Residual risk

- `PraxisPresentationEvent.name` remains a stringly presentation surface by design, so future run event additions will still require explicitly wiring new enum cases through the mapper if they should appear in presentation state.
- This package aligns only the known `run.*` bridge events; other presentation-specific event names would need separate review if they are introduced later.
