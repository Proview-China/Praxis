## 2026-04-11 TAP status readiness surface

### Summary

- Added a standalone host-neutral `readbackTapStatus` surface instead of folding TAP approval pressure into `readbackCmpStatus`.
- Kept the surface TAP-scoped and wired it through `PraxisRuntimeUseCases -> PraxisRuntimeFacades -> PraxisRuntimeInterface`.
- Reused existing host truth:
  - registered host capability surfaces
  - CMP control-derived TAP mode
  - persisted CMP peer approval descriptors

### Why this boundary

- `readbackCmpStatus` should remain focused on CMP object-model/runtime orchestration state.
- TAP readiness needs to stay readable on its own so future FFI/export callers can inspect:
  - current TAP mode
  - human-gate pressure
  - available capability surfaces
  - latest approval summary
without first entering CMP-specific status panels.

### Implemented shape

- `readbackTapStatus(projectID:agentID:)`
  - project-scoped, optional target-agent scoping
  - reports:
    - TAP mode
    - risk level
    - human-gate state
    - available capability IDs/count
    - pending/approved approval counts
    - latest approval capability + decision summary
    - plain-language readiness summary
- `PraxisCmpPeerApprovalStoreContract`
  - now supports `describeAll(_:)` so status surfaces can summarize approval pressure instead of reading only one latest record

### Verification

- `swift test` passed after landing the new surface.
- Current Swift package snapshot: `138` tests / `39` suites.

### Follow-up

- The next natural extension is to add a small TAP runtime event/history surface so callers can inspect approval state transitions, not just the latest readiness summary.
