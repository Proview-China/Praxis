## 2026-04-13 CMP/MP domain reference typing under interface

### What changed

- Tightened CMP runtime-use-case commands to accept domain IDs instead of naked strings where the domain already had stable identifiers:
  - `PraxisRecoverCmpProjectCommand.snapshotID -> PraxisCmpSnapshotID?`
  - `PraxisCommitCmpFlowCommand.eventIDs -> [PraxisCmpEventID]`
  - `PraxisMaterializeCmpFlowCommand.snapshotID -> PraxisCmpSnapshotID?`
  - `PraxisMaterializeCmpFlowCommand.projectionID -> PraxisCmpProjectionID?`
  - `PraxisRetryCmpDispatchCommand.packageID -> PraxisCmpPackageID`
- Tightened MP ingest command to use the CMP checked snapshot identifier explicitly:
  - `PraxisIngestMpCommand.checkedSnapshotRef -> PraxisCmpSnapshotID`
- Tightened CMP recovery/result and facade DTO surfaces to expose existing domain IDs instead of stringly references:
  - recovery `snapshotID/packageID`
  - flow commit `deltaID/snapshotCandidateID`
  - flow resolve `snapshotID`
  - flow materialize `packageID`
  - flow dispatch `dispatchID` as `PraxisCmpDispatchReceiptID`
  - flow history `snapshotID/packageID`
- Kept `PraxisRuntimeInterface` host-neutral and thin:
  - interface request payloads still use opaque `PraxisRuntimeInterfaceReferenceID`
  - interface services now map those opaque refs into CMP/MP domain IDs before calling facades/use cases
  - wire JSON shape remains stable string payloads
- Removed redundant string re-wrapping inside use-case implementations so typed commands are now the internal truth source.

### Why this belongs to the host-neutral track

- The interface no longer feeds CMP/MP flow surfaces with naked string references when the domain already defines stable IDs.
- The middle layer now distinguishes:
  - opaque interface reference handles at the boundary
  - domain-native CMP identifiers inside use cases and facade DTOs
- No CLI/UI/platform/provider semantics were introduced into runtime DTOs.

### Validation

- `swift test --filter PraxisRuntimeUseCasesTests`
- `swift test --filter PraxisRuntimeFacadesTests`
- `swift test --filter HostRuntimeInterfaceTests`
- `swift test`

Full snapshot after this package: `330 tests / 53 suites` passed.

### Residual risk

- This package did not migrate run/transition/internal state identifiers; it only tightened CMP/MP references already backed by existing CMP ID types.
- `RuntimeInterfaceReferenceID` remains the boundary type for wire payloads by design; only the inside of the host-neutral middle layer was tightened.
- Some readback-oriented facade DTOs still expose package references as plain strings where that surface was outside this package's minimum scope, such as `latestPackageID` on certain aggregate panels.

### Next entry point

- Continue hunting remaining host-neutral string references that already have an existing domain ID, especially in aggregate CMP readback/status surfaces and any remaining MP/CMP DTO fields that still only expose raw strings without needing to.
