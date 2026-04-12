# 2026-04-13 Runtime Interface Event Name Typed Contract

## What changed

- Introduced `PraxisRuntimeInterfaceEventName` in `PraxisRuntimeInterfaceModels` and changed `PraxisRuntimeInterfaceEvent.name` from `String` to the typed enum.
- Kept the JSON codec shape stable by using raw values such as `cmp.session.opened`, `run.started`, and `tap.status.readback` as the enum wire format.
- Updated `PraxisRuntimeInterfaceServices` to emit typed event names instead of raw `"cmp.*"`, `"run.*"`, and `"tap.*"` string literals.
- Addressed review feedback by removing the public `PraxisRuntimeInterfaceEvent.init(name: String, ...)` backdoor and removing `ExpressibleByStringLiteral` from `PraxisRuntimeInterfaceEventName`.
- Updated directly related tests to construct and assert runtime interface event names with explicit enum cases instead of string literals.
- Added runtime interface codec coverage for event-name round-trip stability and unknown raw-value decode rejection.

## Why this stays scoped to the runtime interface

- The enum only models the stable event channels currently emitted by `PraxisRuntimeInterface`.
- It intentionally does not widen into CLI, UI, provider, platform, or transport-specific event semantics.
- No other runtime interface event payload fields such as `detail`, `intentID`, `runID`, `sessionID`, or snapshot titles were changed.

## Validation

- `swift test --filter HostRuntimeInterfaceTests`
- `swift test --filter PraxisCLITests`
- `swift test`

## Residual risk

- The typed contract currently covers only the event names already emitted by `PraxisRuntimeInterfaceServices`; adding new runtime interface events will require explicitly extending the enum.
- Removing the string-based construction surface means future test doubles and fixtures must use explicit enum cases when building runtime interface events.
