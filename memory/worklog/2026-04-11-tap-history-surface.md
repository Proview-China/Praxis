## 2026-04-11 TAP history surface

### Summary

- Added a standalone host-neutral `readbackTapHistory` surface on the inspection/TAP side.
- Reused persisted CMP peer approval descriptors to expose recent TAP activity without forcing callers through CMP status panels.
- Kept the surface explicitly bounded: this is a bounded activity feed reconstructed from host-backed approval truth, not a full append-only audit/event ledger.

### Implemented shape

- `readbackTapHistory(projectID:agentID:limit:)`
  - project-scoped with optional target-agent scoping
  - returns:
    - total persisted activity count
    - bounded recent entries
    - route/outcome/human-gate state
    - requested tier
    - capability key
    - decision summary
    - updated timestamp
- `PraxisCmpPeerApprovalStoreContract.describeAll(_:)`
  - added to support TAP history and future readiness/activity summaries

### Boundary decision

- TAP history currently derives from persisted approval descriptors only.
- That means:
  - it is good enough for inspection/readback/export use cases
  - it should not yet be described as a lossless event stream
- If the project later needs a true audit trail, that should land as a dedicated TAP runtime event store instead of overloading the current peer approval registry.

### Verification

- `swift test` passed after landing the surface.
- Current Swift package snapshot: `139` tests / `39` suites.

### Follow-up

- The next natural step is a true TAP runtime event log or audit store so `TapHistory` can evolve from “latest approval activity feed” into an append-only replayable trail.
