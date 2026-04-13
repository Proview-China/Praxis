# Slice 2: SQLite Schema Policy And Signature Hardening

## What changed

- Refined the local runtime SQLite baseline guard into an explicit private schema policy decision layer inside `PraxisLocalHostAdapters.swift`.
- Introduced `LocalSQLiteSchemaPolicyDecision` so the runtime now resolves schema handling into named decisions before mutating the database:
  - fresh init
  - legacy adopt
  - current reopen
  - unsupported older
  - unsupported future
  - incompatible schema
- Upgraded managed-table compatibility checks from column-name set comparison to lightweight column signature comparison based on `PRAGMA table_info`.
- The signature check now validates:
  - column name
  - declared type
  - `NOT NULL`
  - primary-key ordinal

## Why this changed

- The previous baseline versioning work already introduced `PRAGMA user_version = 1`, but the schema policy was still implicit inside a switch and compatibility still trusted matching column names alone.
- That left an obvious gap where a table could preserve the same column names while drifting in type or key semantics.
- This slice keeps the same public API and baseline scope, but makes the acceptance policy more explicit and harder to accidentally re-bless.

## Tests

- Added a legacy unversioned rejection case for matching column names with incompatible signatures.
- Added a current-version rejection case for matching column names with incompatible signatures.
- Verification run:
  - `swift test --filter HostRuntimeSurfaceTests`
  - `swift test`

## Residual

- There is still no direct regression sample for the `unsupported older` branch because the current baseline only defines schema version `1`, and `0` is intentionally reserved for unversioned adoption semantics.
- The new signature regression cases currently exercise declared-type drift. They do not yet add dedicated samples for `NOT NULL` drift or primary-key ordinal drift.
- Compatibility remains intentionally scoped to runtime-managed tables only; unrelated user tables are still ignored by this policy.
