# 2026-04-12 TAP Runtime Event Kind Typed Contract Hardening

## What changed

- Introduced `PraxisTapRuntimeEventKind` in `PraxisInfraContracts` and changed `PraxisTapRuntimeEventRecord.eventKind` from `String` to the typed enum.
- Updated `PraxisRuntimeUseCases` TAP append and legacy history fallback paths to branch on `PraxisTapRuntimeEventKind` instead of raw string literals.
- Tightened legacy TAP history outcome fallback so it only accepts a legacy raw value when it matches the typed `record.eventKind`, instead of accepting any unrelated TAP event raw value.
- Kept the external `Codable` shape stable by relying on the enum raw values such as `peer_approval_requested` and `dispatch_blocked`.
- Added targeted contract tests for TAP runtime event codec round-trip and unknown raw-value rejection.
- Added use-case tests that cover both successful legacy event-kind fallback and mismatched legacy outcome raw-value rejection.

## Why this belongs to the host-neutral path

- TAP runtime event kind is a stable runtime classification contract shared by neutral readback and audit flows.
- The event kind should not remain a stringly convention because runtime history fallback and governance summaries branch on its finite semantic values.

## Validation

- `swift test --filter PraxisInfraContractsTests`
- `swift test --filter HostContractSurfaceTests`
- `swift test --filter HostRuntimeSurfaceTests`
- `swift test --filter PraxisRuntimeUseCasesTests`
- `swift test`

## Residual risk

- This package intentionally does not tighten other TAP metadata keys such as `requestedTier`, `route`, `outcome`, or `humanGateState`.
- The runtime history fallback still depends on legacy event-kind categories for older persisted records. This package typed the contract and fallback branching, but it intentionally did not redesign the legacy fallback model itself.
