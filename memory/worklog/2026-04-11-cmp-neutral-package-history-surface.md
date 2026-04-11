# 2026-04-11 CMP Neutral Package And History Surface

## Summary

- Completed the second half of the host-neutral CMP flow surface across:
  - `PraxisRuntimeUseCases`
  - `PraxisRuntimeFacades`
  - `PraxisRuntimeInterface`
- Added three runtime-facing actions:
  - `materializeCmpFlow`
  - `dispatchCmpFlow`
  - `requestCmpHistory`

## Swift Reuse

- `materializeCmpFlow`
  - reuses `PraxisProjectionMaterializer`
  - reuses `PraxisMaterializationPlan`
  - reuses `PraxisMaterializeContextPackageInput` / `PraxisMaterializeContextPackageResult`
- `dispatchCmpFlow`
  - reuses `PraxisDeliveryPlanner`
  - reuses `PraxisCmpMqPlanner`
  - reuses `PraxisDispatchContextPackageResult`
  - persists transport-side truth through the current host message bus and delivery truth store when available
- `requestCmpHistory`
  - reuses `PraxisRequestHistoricalContextInput` / `PraxisRequestHistoricalContextResult`
  - reuses `PraxisDeliveryPlanner.requestHistoricalContext`
  - reads host-backed projection descriptors and synthesizes snapshot/package candidates without introducing a new runtime registry

## TS Alignment

- Primary old-TS references:
  - `src/rax/cmp/flow.ts`
  - `src/rax/cmp/readback.ts`
  - `src/agent_core/cmp-service/package-flow-service.ts`
  - `src/agent_core/cmp-service/readback-service.ts`

## Boundary

- This surface now owns:
  - host-neutral context package materialization
  - host-neutral dispatch planning and transport truth updates
  - passive historical context lookup through neutral request/response models
- This surface still does not own:
  - CLI command parsing
  - GUI state mapping
  - a dedicated persisted Swift-side CMP package registry
  - provider/browser/multimodal live execution

## Important Constraint

- `requestCmpHistory` currently reconstructs reusable package candidates from projection descriptors plus checked-snapshot views.
- That is intentional until Swift runtime grows a dedicated package persistence surface; callers still receive a stable host-neutral contract without being tied to CLI or GUI.

## Verification

- `swift test`
  - passed
  - `133` tests / `39` suites
