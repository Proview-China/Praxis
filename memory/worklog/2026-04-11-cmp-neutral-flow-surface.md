# 2026-04-11 CMP Neutral Flow Surface

## Summary

- Added the first host-neutral CMP flow surface across:
  - `PraxisRuntimeUseCases`
  - `PraxisRuntimeFacades`
  - `PraxisRuntimeInterface`
- Covered three flow actions first:
  - `ingestCmpFlow`
  - `commitCmpFlow`
  - `resolveCmpFlow`

## Swift Reuse

- `ingestCmpFlow`
  - reuses `PraxisSectionBuilder`
  - reuses `PraxisCmpFiveAgentPlanner`
  - reuses `PraxisIngestRuntimeContextInput` / `PraxisIngestRuntimeContextResult`
- `commitCmpFlow`
  - reuses `PraxisCmpContextDelta`
  - reuses `PraxisCmpGitPlanner`
  - reuses `PraxisDeliveryPlanner`
  - reuses `PraxisCommitContextDeltaResult`
- `resolveCmpFlow`
  - reuses `PraxisResolveCheckedSnapshotInput` / `PraxisResolveCheckedSnapshotResult`
  - reads host-backed projection descriptors from the current projection store
  - synthesizes a checked snapshot view from the latest matching projection descriptor

## TS Alignment

- Primary old-TS references:
  - `src/rax/cmp/flow.ts`
  - `src/agent_core/cmp-service/active-flow-service.ts`
  - `src/agent_core/cmp-service/package-flow-service.ts`

## Boundary

- Current flow surface owns:
  - neutral request/response contracts
  - deterministic section lowering for ingest
  - delta/candidate shaping for commit
  - projection-backed checked snapshot resolution
- Current flow surface does not yet own:
  - a dedicated persisted CMP object-model registry inside Swift runtime
  - materialize / dispatch / requestHistory runtime interface surfaces
  - full five-agent live execution state

## Important Constraint

- `resolveCmpFlow` intentionally does not force a synthetic default lineage filter when callers omit `lineageID`.
- This keeps the neutral resolve surface compatible with current local runtime projections, which may have been written by other runtime paths before a dedicated CMP flow state holder exists.

## Verification

- `swift test`
  - passed
  - `133` tests / `39` suites
