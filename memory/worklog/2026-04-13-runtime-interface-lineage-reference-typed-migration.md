## 2026-04-13 - RuntimeInterface lineage reference typed migration

### What changed

- Tightened four CMP runtime-interface request payloads so `lineageID` now uses `PraxisRuntimeInterfaceReferenceID?` instead of bare `String?`:
  - `PraxisRuntimeInterfaceRecoverCmpProjectRequestPayload`
  - `PraxisRuntimeInterfaceIngestCmpFlowRequestPayload`
  - `PraxisRuntimeInterfaceCommitCmpFlowRequestPayload`
  - `PraxisRuntimeInterfaceResolveCmpFlowRequestPayload`
- Updated `PraxisRuntimeInterfaceServices` to keep the interface boundary host-neutral and thin by mapping those opaque interface references into downstream `PraxisCmpLineageID` values at the service edge.
- Kept runtime-interface request JSON stable. `lineageID` still encodes and decodes as a plain string raw value inside the existing request envelope.

### Why it changed

- `requestCmpHistory` already moved to an interface-owned query shape with `PraxisRuntimeInterfaceReferenceID`.
- These four payloads were the remaining obvious CMP request lineage surfaces still exposing raw strings at the runtime-interface boundary.
- This package closes that inconsistency without changing request kinds, use-case truth models, or host behavior.

### Verification

- Added codec roundtrip coverage for recover/ingest/commit/resolve request payloads to assert `lineageID` remains a string in outward JSON while decoding back into typed interface references.
- Added a service-level mapping test proving a padded opaque `lineageID` is forwarded into a downstream `PraxisCmpLineageID` without trimming or blank-collapsing.

### Residuals

- This package does not change `PraxisRuntimeUseCases` command ownership or remove the remaining source-compatibility string initializers there.
- Other payload families remain unchanged by design.
