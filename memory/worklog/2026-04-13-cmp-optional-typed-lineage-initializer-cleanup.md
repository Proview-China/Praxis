## 2026-04-13 - CMP optional typed lineage initializer cleanup

### What changed

- Unified the public lineage-bearing initializers for four CMP commands so callers can pass `PraxisCmpLineageID?` directly:
  - `PraxisRecoverCmpProjectCommand`
  - `PraxisIngestCmpFlowCommand`
  - `PraxisCommitCmpFlowCommand`
  - `PraxisResolveCmpFlowCommand`
- Kept the existing string-based source-compatibility entry points in place and marked them as disfavored overloads so typed optional callers and omitted-lineage callers resolve to the new canonical public initializer.
- Removed the repeated `if let lineageID` initializer selection in `PraxisRuntimeInterfaceServices`; the interface now always maps the boundary value once and forwards it into the unified optional-typed command initializer.

### Why it changed

- The previous package typed CMP lineage references at the runtime-interface boundary, but `PraxisRuntimeInterfaceServices` still had to branch four times because the downstream command public API only accepted either a non-optional typed lineage or a legacy string surface.
- This package keeps the host-neutral boundary unchanged while reducing constructor-shape coupling between the interface layer and the use-case command layer.

### Verification

- Updated `PraxisRuntimeUseCasesTests` to prove the four commands accept optional typed lineage values directly while legacy string convenience and omitted-lineage call sites still coexist.
- Added a runtime-interface behavior test that exercises recover/ingest/commit/resolve through the unified optional-typed command path and confirms the downstream commands still see the same lineage semantics.
- Validation:
  - `swift test --filter PraxisRuntimeUseCasesTests`
  - `swift test --filter HostRuntimeInterfaceTests`
  - `swift test`

### Residuals

- This package only removes duplicated initializer selection for the four CMP lineage-bearing commands listed above.
- Other command families still use their existing initializer shapes by design.
