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
- Service mapping now preserves opaque reference raw values exactly as supplied or produced, while still rejecting required all-whitespace references at the runtime-interface boundary.
- Required opaque references keep their prior failure semantics:
  - `packageID` continues to fail with `missingRequiredField`
  - `checkedSnapshotRef` continues to fail with `invalidInput`
- Optional continuation references such as `recoverCmpProject.snapshotID` and `materializeCmpFlow.snapshotID/projectionID` now preserve explicit blank raw values instead of collapsing them to omission, so downstream use cases can keep their existing failure-or-constrain semantics.
- Downstream facade and use-case contracts still receive raw strings via `rawValue`; no deeper domain typing migration was introduced.

## Validation

- `swift test --filter HostRuntimeInterfaceTests`
- `swift test --filter HostRuntimeSurfaceTests`
- `swift test`

All checks passed locally. Current full-suite snapshot: `329 tests / 53 suites`.

## Residual Risk

- This package only continues the runtime-interface reference surface. Domain-owned identifiers in `PraxisRun`, `PraxisTransition`, `PraxisState`, and non-interface CMP/MP models remain string-based by design.
- `branchRef` / `baseRef` and other free-form textual references remain residuals because they are not clean opaque runtime-interface references.
- Compatibility now depends on tests continuing to guard against accidental trimming or blank-to-`nil` collapse for opaque references; future interface work should extend those tests before refactoring shared normalization helpers.
