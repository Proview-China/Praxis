# RuntimeInterface Reference Surface Continuation

Date: 2026-04-13

## What Changed

- Extended `PraxisRuntimeInterfaceReferenceID` across additional runtime-interface-owned outward reference fields while preserving the existing JSON string wire shape.
- Hardened `PraxisRuntimeInterfaceSnapshot.checkpointReference` as a typed opaque reference.
- Hardened the following request payload fields as typed opaque references:
  - `PraxisRuntimeInterfaceRecoverCmpProjectRequestPayload.snapshotID`
  - `PraxisRuntimeInterfaceMaterializeCmpFlowRequestPayload.snapshotID`
  - `PraxisRuntimeInterfaceMaterializeCmpFlowRequestPayload.projectionID`
  - `PraxisRuntimeInterfaceRetryCmpDispatchRequestPayload.packageID`
  - `PraxisRuntimeInterfaceMpIngestRequestPayload.checkedSnapshotRef`
- Kept `branchRef`, `baseRef`, and deeper domain-owned identifiers unchanged to avoid expanding into Run/Transition/State or CMP history model migration.

## Boundary Notes

- The change stays inside `PraxisRuntimeInterface` outward models, service mapping, and interface-level tests.
- Service mapping now normalizes optional opaque references so blank values become `nil`.
- Required opaque references keep their prior failure semantics:
  - `packageID` continues to fail with `missingRequiredField`
  - `checkedSnapshotRef` continues to fail with `invalidInput`
- Downstream facade and use-case contracts still receive raw strings via `rawValue`; no deeper domain typing migration was introduced.

## Validation

- `swift test --filter HostRuntimeInterfaceTests`
- `swift test --filter HostRuntimeSurfaceTests`
- `swift test`

All checks passed locally. Current full-suite snapshot: `326 tests / 53 suites`.

## Residual Risk

- This package only continues the runtime-interface reference surface. Domain-owned identifiers in `PraxisRun`, `PraxisTransition`, `PraxisState`, and non-interface CMP/MP models remain string-based by design.
- `branchRef` / `baseRef` and other free-form textual references remain residuals because they are not clean opaque runtime-interface references.
