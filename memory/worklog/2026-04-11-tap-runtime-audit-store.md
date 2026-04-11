# 2026-04-11 TAP Runtime Audit Store

- Added a host-neutral append-only `PraxisTapRuntimeEventStoreContract` to keep TAP history as runtime audit truth instead of rebuilding it only from latest peer-approval descriptors.
- Wired the new store through `PraxisHostAdapterRegistry`, `PraxisDependencyGraph`, scaffold defaults, and local SQLite defaults so `InspectionFacade.readbackTapHistory` can prefer runtime events across independent local registries.
- Updated CMP peer-approval requests to append TAP runtime events while preserving the existing peer-approval descriptor store for latest-state readback.
- Kept `readbackTapHistory` backward-compatible by falling back to descriptor reconstruction when an event store is absent or when older persisted data predates the new audit lane.
