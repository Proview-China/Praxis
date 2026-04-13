# Runtime Kit High-Level Swift API

## Summary

- Added `PraxisRuntimeKit` as the first caller-friendly Swift framework target above the host-neutral runtime layers.
- Exposed direct helpers for local runtime creation, goal source preparation, goal normalization and compilation, `runGoal`, `resumeRun`, and common TAP/CMP/MP inspections.
- Added project-scoped `tap`, `cmp`, and `mp` subclients so repeated runtime calls no longer have to mirror lower-level facade grouping.
- Kept transport, FFI, and composition details out of the public `PraxisRuntimeKit` surface after tightening the initial implementation.
- Follow-up API tightening then removed the duplicated top-level helpers again, shrinking the stable surface to `runs`, `tap`, `cmp`, and `mp`.
- A second tightening pass then collapsed the project-scoped surface further around grouped `overview`, `approvals`, and `memory(...)` entrypoints.
- A third tightening pass then replaced remaining multi-parameter public methods with RuntimeKit-owned typed input and options models.
- A fourth tightening pass then replaced the remaining bare `project`, `run`, `session`, `agent`, `capability`, and `memory` string identifiers with RuntimeKit-owned lightweight ref types.

## Files

- `Package.swift`
- `Sources/PraxisRuntimeGateway/PraxisRuntimeGateway.swift`
- `Sources/PraxisRuntimeKit/PraxisRuntimeKit.swift`
- `Sources/PraxisRuntimeKit/PraxisRuntimeClient.swift`
- `Sources/PraxisRuntimeKit/PraxisRuntimeRunClient.swift`
- `Sources/PraxisRuntimeKit/PraxisRuntimeTapClient.swift`
- `Sources/PraxisRuntimeKit/PraxisRuntimeCmpClient.swift`
- `Sources/PraxisRuntimeKit/PraxisRuntimeMpClient.swift`
- `Sources/PraxisRuntimeKit/PraxisRuntimeKitInputs.swift`
- `Sources/PraxisRuntimeKit/PraxisRuntimeKitRefs.swift`
- `Tests/PraxisRuntimeKitTests/PraxisRuntimeKitTests.swift`
- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeTopologyTests.swift`
- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeBoundaryGuardTests.swift`
- `README.md`
- `SWIFT_REFACTOR_PLAN.md`

## Validation

- `swift test --filter PraxisRuntimeKitTests`
- `swift test --filter HostRuntimeBoundaryGuardTests`
- `swift test --filter HostRuntimeTopologyTests`
- `swift test`

## Notes

- `PraxisRuntimeKit` now builds local-default runtime facades through `PraxisRuntimeGatewayFactory.makeRuntimeFacade(rootDirectory:)`, so callers do not need to see `PraxisHostAdapterRegistry` or `PraxisRuntimeBlueprint`.
- The lower-level `PraxisRuntimeFacade` graph remains an implementation detail of `PraxisRuntimeKit`, not part of its public API.
- Project-scoped subclients now carry repeated `projectID` context for TAP/CMP/MP workflows while still returning the stable host-neutral snapshots defined by `PraxisRuntimeFacades`.
- Boundary guards now fail if `PraxisRuntimeKit` reintroduces `PraxisRuntimeComposition`, `PraxisRuntimeInterface`, `PraxisFFI`, `PraxisHostAdapterRegistry`, `PraxisRuntimeBlueprint`, or public facade escape hatches.
- Boundary guards also fail if the root `PraxisRuntimeClient` grows back top-level `runGoal`, `resumeRun`, goal-preparation helpers, or duplicate TAP inspection/readback shortcuts.
- Boundary guards now also reject older flat project-client methods when grouped overview/resource entrypoints are expected instead.
- Boundary guards now also reject older flat multi-parameter signatures once a typed RuntimeKit input model exists for that workflow.
- Boundary guards now also reject bare string identifier signatures once a RuntimeKit ref type exists for that identifier family.
