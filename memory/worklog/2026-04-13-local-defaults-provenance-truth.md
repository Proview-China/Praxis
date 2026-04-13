## Package

`localDefaults provenance truth for MP inspection/smoke`

## What changed

- Added explicit host-surface provenance contracts in `PraxisHostAdapterRegistry` for the MP-related provider/browser/multimodal lanes that currently influence inspection and smoke wording.
- Split those provenance values into:
  - `unavailable`
  - `scaffoldPlaceholder`
  - `localBaseline`
  - `composed`
- Updated `scaffoldDefaults()` to mark scaffolded provider/browser/audio/speech/image lanes as `scaffoldPlaceholder`.
- Updated `localDefaults()` to mark the corresponding local heuristic/baseline lanes as `localBaseline`.
- Updated `PraxisMpHostInspectionService` so MP inspection and smoke summaries now reflect provenance truth instead of treating every non-nil adapter as a stronger composed/host-backed surface.
- Fixed `PraxisDependencyGraph` so overriding `providerInferenceExecutor` no longer leaves the graph carrying stale provenance from the original registry.

## Why now

- The remaining risk on the `localDefaults` path was not missing MP surfaces; it was provenance drift.
- Before this package, inspection and smoke wording could overstate the meaning of adapter presence:
  - `localDefaults()` could read stronger than a local heuristic baseline.
  - `scaffoldDefaults()` could read stronger than scaffold placeholders.
  - `PraxisDependencyGraph` override paths could preserve old provenance after replacing the actual executor.
- This package hardens the meaning of "available" without changing wire shape or widening the public runtime surface.

## Host-neutral boundary

- The new provenance values stay inside composition/use-case assembly and wording logic.
- No runtime interface DTO field names or shapes changed.
- No CLI, UI, terminal, platform-control, or provider raw-payload semantics were introduced into the host-neutral middle layer.

## Validation

- `swift test --filter HostRuntimeCompositionGuardTests`
- `swift test --filter HostRuntimeSurfaceTests`
- `swift test --filter PraxisRuntimeUseCasesTests`
- `swift test --filter HostRuntimeInterfaceTests`
- `swift test --filter PraxisRuntimeFacadesTests`
- `swift test`

Current local snapshot after this package:

- `352 tests`
- `53 suites`

## Residuals

- The explicit provenance contract currently covers the MP inspection/smoke lanes that this package actually uses.
- If future work adds more overrideable host surfaces to `PraxisDependencyGraph`, those paths must also define provenance propagation rules instead of assuming the old registry values remain valid.
- This is a behavior regression net, not a formal proof that every host-surface provenance path is covered.

## Next package

- Audit the remaining CMP/TAP readback summaries that still use broad `host-backed truth` phrasing and decide which ones are genuinely acceptable and which should be narrowed to provenance-neutral wording.
