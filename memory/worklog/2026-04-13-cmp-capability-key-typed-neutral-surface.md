# 2026-04-13 CMP capability key typed neutral surface

## What changed

- Hardened the host-neutral CMP/TAP capability chain so the public contracts listed below now carry `PraxisCapabilityID` instead of raw `String` / `String?`:
  - `PraxisRequestCmpPeerApprovalCommand`
  - `PraxisCmpPeerApproval`
  - `PraxisReadbackCmpPeerApprovalCommand`
  - `PraxisDecideCmpPeerApprovalCommand`
  - `PraxisCmpPeerApprovalReadback`
  - `PraxisTapHistoryEntry`
  - `PraxisTapStatusReadback.latestCapabilityKey`
  - matching facade snapshots in `PraxisRuntimeFacadeDTOs`
  - matching runtime interface payloads and snapshots in `PraxisRuntimeInterfaceModels`

- Kept `availableCapabilityIDs: [String]` unchanged on purpose. This package only sealed the minimum peer-approval / TAP capability key loop.

- Moved capability normalization and validation into `PraxisRuntimeUseCases` instead of only swapping DTO field types:
  - peer approval request and decision paths normalize `PraxisCapabilityID.rawValue` before using it
  - store/query boundaries still convert to raw strings only at the infra edge
  - TAP history reconstruction now returns typed `PraxisCapabilityID`
  - TAP status latest capability is reconstructed as typed `PraxisCapabilityID`
  - corrupt blank capability keys in persisted CMP/TAP records now fail through stable `invalidInput` semantics instead of leaking raw strings upward
  - optional readback `capabilityKey` filters still preserve the old compatibility rule: blank input is normalized to `nil`, including the no-hit path

- Updated runtime interface handling so request payload validation trims and validates `PraxisCapabilityID` before dispatching to facades, while JSON still round-trips as stable string fields.

## Why this package exists

- This closes one specific host-neutral gap: capability identity is now a typed semantic value across the neutral `UseCases -> Facades -> RuntimeInterface` surface for CMP peer approvals and TAP readbacks.
- It avoids leaking raw string capability keys deeper into orchestration logic while still preserving the existing persisted and wire JSON shape.

## Verification

- `swift test --filter PraxisRuntimeUseCasesTests`
- `swift test --filter PraxisRuntimeFacadesTests`
- `swift test --filter HostRuntimeInterfaceTests`
- `swift test --filter HostRuntimeSurfaceTests`
- `swift test`

## Remaining risks

- `availableCapabilityIDs` is still stringly by design and should be handled in its own package.
- Infra contracts such as `PraxisCmpPeerApprovalDescriptor` and `PraxisTapRuntimeEventRecord` still persist raw string capability keys at the storage boundary; that is intentional, but they remain the next place where corrupted raw data can enter before neutral reconstruction rejects it.
