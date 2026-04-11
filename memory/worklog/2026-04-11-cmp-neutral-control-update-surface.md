# 2026-04-11 CMP Neutral Control Update Surface

## Summary

- Extended the CMP control surface from readback-only defaults into a host-backed mutable surface.
- Kept the surface host-neutral and runtime-first instead of routing mutations through CLI or GUI.

## What Was Added

- Added a thin host persistence contract for CMP control settings:
  - `PraxisCmpControlStoreContract`
  - `PraxisCmpControlDescriptor`
  - `PraxisCmpControlQuery`
  - `PraxisCmpControlStoreWriteReceipt`
- Added local and fake implementations:
  - `PraxisFakeCmpControlStore`
  - `PraxisLocalCmpControlStore`
- Wired the control store into:
  - `PraxisHostAdapterRegistry`
  - `PraxisDependencyGraph`
  - local SQLite runtime schema via `cmp_controls`

## Runtime Surface Changes

- Added a new mutation command path:
  - `PraxisUpdateCmpControlCommand`
  - `PraxisCmpControlUpdate`
- Added the corresponding use case, facade, and runtime-interface request:
  - `PraxisUpdateCmpControlUseCase`
  - `PraxisCmpFacade.updateControl(_:)`
  - `RuntimeInterface.updateCmpControl`
- `readbackCmpControl` and `readbackCmpStatus` now resolve persisted control settings first, then fall back to the baseline defaults.

## Boundary

- The control store is intentionally thin:
  - it persists neutral CMP control settings only
  - it does not introduce a new live orchestrator
  - it does not bind contract semantics to CLI commands or Apple UI state
- Mutable TAP-backed peer approval and human-gate bridging remain the next follow-up instead of being bundled into this step.

## Verification

- Added facade/runtime-interface regression coverage for control update and readback.
- Added fake-store coverage for the new control store contract.
- `swift test` passed with `136` tests across `39` suites.
