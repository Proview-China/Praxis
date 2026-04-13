# Strip CLI, AppleUI, and Presentation Bridge From Main Package

## Summary

- Removed `PraxisCLI`, `PraxisAppleUI`, and `PraxisRuntimePresentationBridge` from the Swift package graph.
- Reframed the active runtime boundary as `RuntimeComposition -> UseCases -> Facades -> RuntimeInterface -> RuntimeGateway -> FFI`.
- Kept host-neutral gateway factory ergonomics stable by restoring convenience overloads that default to the gateway blueprint.

## Removed

- `Sources/PraxisCLI`
- `Sources/PraxisAppleUI`
- `Sources/PraxisRuntimePresentationBridge`
- `Tests/PraxisCLITests`
- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimePresentationBridgeTests.swift`

## Updated

- `Package.swift`
- `Sources/PraxisRuntimeFacades/PraxisRuntimeFacades.swift`
- `Sources/PraxisRuntimeGateway/PraxisRuntimeGateway.swift`
- `Sources/PraxisRuntimeUseCases/PraxisUseCaseImplementations.swift`
- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeTopologyTests.swift`
- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeBoundaryGuardTests.swift`
- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeInterfaceTests.swift`
- `Tests/PraxisHostRuntimeArchitectureTests/HostRuntimeSurfaceTests.swift`
- `SWIFT_REFACTOR_PLAN.md`

## Validation

- `swift test` passes after the package topology shrink.
- Current snapshot after shell stripping is `361 tests / 51 suites`.

## Notes

- Negative architecture assertions still mention the removed targets to guard against reintroduction.
- The next framework-focused step should be a more ergonomic high-level Swift API so direct callers do not need to live on transport-style runtime envelopes.
