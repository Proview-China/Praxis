# 2026-04-13 MP Host-Neutral Wire-Shape & Boundary Behavior Hardening

## What changed

- Backfilled `HostRuntimeInterfaceTests` for the six MP workflow requests:
  - `ingestMp`
  - `alignMp`
  - `promoteMp`
  - `archiveMp`
  - `resolveMp`
  - `requestMpHistory`
- Added real `RuntimeInterfaceServices` request-mapping guards for:
  - blank `checkedSnapshotRef` rejection on `ingestMp`
  - padded exact-match fields on `resolveMp`, `requestMpHistory`, `alignMp`, `promoteMp`, and `archiveMp`
- Added one real MP use-case execution-path test:
  - `PraxisIngestMpUseCase`
  - `PraxisResolveMpUseCase`
  - `PraxisRequestMpHistoryUseCase`
  This now checks encoded result payloads after actual use-case execution instead of only hand-encoding DTOs.
- Added one real facade-path test through `PraxisRuntimeGatewayFactory.makeRuntimeFacade(...)`:
  - `mpFacade.ingest`
  - `mpFacade.resolve`
  - `mpFacade.requestHistory`
  This now checks encoded snapshot payloads after actual facade mapping instead of only hand-encoding snapshots.

## Why this package exists

The remaining non-UI risk on the MP path was not a large model refactor. It was the absence of a tight behavior net around the `RuntimeInterface -> UseCase -> Facade` boundary. This package turns that risk into explicit tests so future cleanup cannot silently trim, collapse, or presentation-decorate MP request/response fields.

## Validation

- `swift test --filter HostRuntimeInterfaceTests`
- `swift test --filter PraxisRuntimeUseCasesTests`
- `swift test --filter PraxisRuntimeFacadesTests`
- `swift test`

## Residual risks

- This package does not migrate MP `memoryID` / `projectID` / `sessionID` into new domain identifier types.
- `RuntimeInterfaceServices` still contains thin per-branch mapping code; this package only hardens its behavior surface.
- The request-side guards are representative, not exhaustive. They now explicitly cover:
  - `ingestMp.checkedSnapshotRef`
  - `resolveMp.requesterSessionID`
  - `requestMpHistory.requesterSessionID`
  - `alignMp.memoryID`
  - `promoteMp.memoryID`
  - `promoteMp.targetSessionID`
  - `archiveMp.memoryID`
- The result-side assertions are also representative, not a full field-by-field wire snapshot suite for every MP request/result pair.
- `searchMp`, `readbackMp`, and `smokeMp` were already covered elsewhere and were not expanded into a new exhaustive boundary matrix in this package.
- HostContracts / provider / browser / user-io seams remain outside this scope.
