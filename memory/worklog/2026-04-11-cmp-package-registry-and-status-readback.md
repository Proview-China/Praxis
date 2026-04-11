# 2026-04-11 CMP Package Registry And Status Readback

## Summary

- Continued both CMP follow-up lines in parallel:
  - added a host-backed CMP package registry baseline
  - added a host-neutral CMP status/readback surface for roles, control, and object-model summaries

## Package Registry

- Added a thin host contract:
  - `PraxisCmpContextPackageStoreContract`
- Added shared request/descriptor models:
  - `PraxisCmpContextPackageDescriptor`
  - `PraxisCmpContextPackageQuery`
  - `PraxisCmpContextPackageStoreWriteReceipt`
- Added implementations:
  - `PraxisFakeCmpContextPackageStore`
  - `PraxisLocalCmpContextPackageStore`
- Wired the store into:
  - `PraxisHostAdapterRegistry`
  - `PraxisDependencyGraph`
  - local SQLite runtime schema via `cmp_packages`

## Runtime Flow Changes

- `materializeCmpFlow`
  - now persists a package descriptor into the package registry when available
- `dispatchCmpFlow`
  - now updates the stored package descriptor to dispatched state
  - still persists delivery truth separately
- `requestCmpHistory`
  - now prefers package registry reads over projection-only reconstruction
  - still falls back to projection-backed synthesis when the registry is empty

## Status Readback

- Added a new host-neutral runtime surface:
  - `readbackCmpStatus`
- This surface currently reports:
  - control defaults aligned with current TS CMP defaults
  - five-agent role readback summary
  - object-model counts for projections / snapshots / packages / delivery truth
  - latest package / latest dispatch hints
- The current implementation reconstructs role state from host-backed runtime truth rather than from a dedicated live five-agent runtime ledger.

## Boundary

- The new package registry is intentionally thin:
  - it stores host-neutral package descriptors
  - it does not introduce a second runtime orchestrator
  - it does not bind callers to CLI or GUI concerns
- The new status surface is also intentionally readback-first:
  - it summarizes current runtime truth
  - it does not claim to be a full live-control plane yet

## TS Alignment

- Primary old-TS references:
  - `src/rax/cmp/flow.ts`
  - `src/rax/cmp/readback.ts`
  - `src/rax/cmp/control.ts`
  - `src/rax/cmp/project.ts`

## Verification

- `swift test`
  - passed
  - `134` tests / `39` suites
