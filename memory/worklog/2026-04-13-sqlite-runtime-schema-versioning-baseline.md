# SQLite Runtime Schema Versioning Baseline

## What changed

- Introduced a formal schema-versioning baseline for the local runtime SQLite store in `PraxisLocalHostAdapters.swift`.
- Defined the current runtime schema version as `1` and enforced it through `PRAGMA user_version`.
- Added runtime schema compatibility checks that validate the runtime-managed tables and their exact baseline column sets before adopting or accepting an existing database.

## Policy

- Fresh database:
  - Create the current runtime schema artifacts.
  - Persist `PRAGMA user_version = 1`.
- Legacy unversioned database that already matches the current runtime schema:
  - Accept a partial legacy materialization when the already-existing runtime-managed tables match the current baseline exactly.
  - Create any missing runtime-managed tables with the baseline schema.
  - Preserve existing records.
  - Persist `PRAGMA user_version = 1`.
- Legacy unversioned database with conflicting runtime-managed tables:
  - Reject adoption.
  - Do not stamp it as version `1`.
- Current-version database:
  - Reopen only when the runtime-managed tables still satisfy the same baseline policy.
  - Reject tampered or incomplete version-`1` layouts instead of silently re-blessing them.
- Database with a future or otherwise unsupported version:
  - Reject opening it with a stable invariant-violation error.

## Why this package exists

- `SWIFT_REFACTOR_PLAN.md` still listed SQLite runtime schema versioning and migration policy as a real residual.
- The previous local runtime store only used `CREATE TABLE IF NOT EXISTS ...`, which left schema truth implicit and provided no policy for unversioned or future-version databases.
- The baseline policy is intentionally narrower than a migration framework: it accepts exact known legacy subsets, fills in missing managed tables, and rejects layouts that do not clearly fit the current baseline.

## Verification

- `swift test --filter HostRuntimeSurfaceTests`
- `swift test`

## Notes

- This is intentionally a baseline policy, not a generic migration framework.
- Validation is limited to runtime-managed table names plus exact baseline column sets; it does not attempt generalized semantic migrations.
- The wire shape and runtime-facing DTO surfaces remain unchanged.
