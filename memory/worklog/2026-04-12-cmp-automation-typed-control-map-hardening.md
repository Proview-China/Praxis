# 2026-04-12 CMP automation typed control map hardening

## What changed

- Added `PraxisCmpAutomationKey` and `PraxisCmpAutomationMap` in `Sources/PraxisCmpTypes/PraxisCmpAutomationTypes.swift`.
- Migrated host-neutral CMP control contracts from `[String: Bool]` to `PraxisCmpAutomationMap`:
  - `PraxisCmpControlSurface`
  - `PraxisUpdateCmpControlCommand`
  - `PraxisCmpControlPanelSnapshot`
  - `PraxisCmpControlUpdateSnapshot`
  - `PraxisRuntimeInterfaceUpdateCmpControlRequestPayload`
- Kept raw-key compatibility at codec boundaries by giving `PraxisCmpAutomationMap` manual keyed `Codable` conformance.
- Hardened `UseCase` logic so default control, dispatch gating, control descriptor load/save, control merging, and TAP metadata emission use typed automation keys instead of string subscripts.
- Left `PraxisCmpControlDescriptor` as the raw infra contract and added explicit descriptor-to-typed validation so bad persisted automation keys fail with stable `invalidInput` errors instead of being normalized or ignored.

## Why this package belongs to the host-neutral lane

- The control surface now exposes stable CMP automation semantics through typed contracts rather than free-form string dictionaries.
- Raw string keys remain only at interface JSON, descriptor persistence, and metadata boundaries where compatibility matters.
- No CLI, UI, platform, or provider-specific semantics were introduced.

## Tests run

- `swift test --filter PraxisRuntimeUseCasesTests`
- `swift test --filter PraxisRuntimeFacadesTests`
- `swift test --filter HostRuntimeInterfaceTests`
- `swift test --filter HostRuntimeSurfaceTests`

## Residual notes

- `PraxisCmpControlDescriptor` still stores raw automation dictionaries by design; this package only hardens the host-neutral boundary around it.
- Other CMP weak-type surfaces such as `capabilityKey` remain out of scope for this package.
