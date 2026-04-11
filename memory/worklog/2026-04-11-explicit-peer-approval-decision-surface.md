# 2026-04-11 Explicit Peer Approval Decision Surface

- Added an explicit host-neutral CMP peer-approval decision surface with `approve`, `reject`, and `release` actions instead of forcing callers to infer gate changes from control updates or TAP readback alone.
- Wired the decision surface through `PraxisRuntimeUseCases`, `PraxisRuntimeFacades`, and `PraxisRuntimeInterface` so hosts can resolve an existing approval request without going through CLI or GUI-specific entry points.
- Reused the existing peer-approval descriptor store as the latest-state truth, updating `outcome`, `humanGateState`, `decisionSummary`, and metadata in place while preserving the original request scope and requested tier.
- Appended explicit TAP runtime lifecycle events for decision mutations so `readbackTapHistory` now reflects both review requests and later human/host resolutions.
