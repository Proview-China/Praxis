## 2026-04-11 CMP peer approval TAP bridge surface

### Summary

- Added a host-neutral CMP peer approval surface that routes through the shared TAP review engine instead of introducing a CMP-local approval policy fork.
- Extended the host adapter registry with a dedicated `cmpPeerApprovalStore` contract plus local SQLite-backed persistence.
- Wired the new surface through `PraxisRuntimeUseCases -> PraxisRuntimeFacades -> PraxisRuntimeInterface` without coupling contracts to CLI or GUI entry points.

### Implemented surface

- `requestCmpPeerApproval`
  - Accepts `projectID`, requester/target agent IDs, `capabilityKey`, requested TAP tier, and a plain-language summary.
  - Resolves effective CMP control for the target agent.
  - Maps CMP control mode into TAP mode and routes through `PraxisReviewDecisionEngine`.
  - Persists the latest approval descriptor when the host provides a peer approval store.
- `readbackCmpPeerApproval`
  - Reads back the latest persisted approval state for one project-scoped query.
  - Returns a stable not-found shape instead of forcing CLI/GUI-specific error handling.

### Boundary decisions

- CMP peer approval does not own a separate review matrix.
  - TAP governance remains the single source of truth for risk/mode/route decisions.
- Peer approval persistence is intentionally thin.
  - The stored descriptor captures request summary, TAP route/outcome, human-gate state, timestamps, and a small metadata bag.
- Current readback is "latest state" only.
  - It is sufficient for control/status surfaces and future FFI export, but not yet a full append-only approval history.

### Verification

- `swift test` passed after the new surface landed.
- Current Swift package snapshot: `137` tests / `39` suites.

### Follow-up

- The next natural step is to let `readbackCmpStatus` or a dedicated TAP status surface summarize pending peer approvals so callers can see review pressure without issuing a dedicated approval query.
- After that, the same host-neutral contract can be exported through the future minimal `PraxisFFI` target.
