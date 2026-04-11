# 2026-04-11 TAP Gated Dispatch And Lifecycle Events

- Extended TAP runtime audit from a single `peer_approval_requested` event into a small lifecycle feed: `peer_approval_requested`, `peer_approval_waiting`, `peer_approval_rejected`, and `gate_released`.
- Connected `CMP control` mutation to TAP audit with `control_updated` so governance history can explain why later dispatch behavior changed.
- Made `dispatchCmpFlow` respect the existing host-neutral `autoDispatch` control gate instead of always publishing. When the gate is closed, dispatch now returns a rejected result, keeps the package materialized, records a pending delivery-truth entry with a blocking reason, and appends a `dispatch_blocked` TAP runtime event.
- When dispatch is allowed, runtime now appends a `dispatch_released` TAP runtime event so TAP history can show both gating and release decisions without relying on CLI or GUI-specific tracing.
