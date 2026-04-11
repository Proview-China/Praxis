# 2026-04-11 Peer Approval Error Contracts

- Added stable runtime-interface error codes for explicit peer-approval decision failures: `cmp_peer_approval_not_found` and `cmp_peer_approval_already_resolved`.
- Kept the domain layer host-neutral by continuing to raise `PraxisError.invalidInput`, while the runtime-interface layer maps well-known message prefixes into the new stable error codes.
- Tightened explicit decision semantics so duplicate `approve/reject/release` operations on an already resolved approval are rejected instead of silently overwriting the latest decision state.
