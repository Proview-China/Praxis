# 2026-04-11 CMP Neutral Roles And Control Readback Surface

## Summary

- Added host-neutral CMP `roles` and `control` readback surfaces on top of the existing project / flow / status chain.
- Kept the new APIs readback-first instead of introducing a mutable control plane at this stage.

## What Was Added

- New `PraxisRuntimeUseCases` commands and readback models:
  - `PraxisReadbackCmpRolesCommand`
  - `PraxisCmpRolesReadback`
  - `PraxisReadbackCmpControlCommand`
  - `PraxisCmpControlReadback`
- New use case protocols and implementations:
  - `PraxisReadbackCmpRolesUseCase`
  - `PraxisReadbackCmpControlUseCase`
- New `PraxisRuntimeFacades` snapshots and facade methods:
  - `PraxisCmpRolesPanelSnapshot`
  - `PraxisCmpControlPanelSnapshot`
  - `readbackRoles(_:)`
  - `readbackControl(_:)`
- New `PraxisRuntimeInterface` request payloads and command cases:
  - `readbackCmpRoles`
  - `readbackCmpControl`

## Boundary

- The new surfaces intentionally reuse the same host-backed runtime truth as `readbackCmpStatus`:
  - projection descriptors
  - package registry descriptors
  - delivery truth records
- This keeps the contract host-neutral and avoids creating a second live CMP orchestrator inside `PraxisRuntimeUseCases`.
- Control remains readback/defaults-oriented for now:
  - execution style
  - mode
  - readback priority
  - fallback / recovery preferences
  - automation gates
- Mutable control-plane operations and TAP-backed approval flows should remain the next follow-up, not part of this step.

## Verification

- Added facade and runtime-interface regression coverage for the new roles/control surfaces.
- `swift test` passed with `136` tests across `39` suites.
