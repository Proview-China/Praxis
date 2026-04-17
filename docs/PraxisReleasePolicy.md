# Praxis Release Policy

This document defines the current release discipline for exported Praxis runtime surfaces.

## Scope

This policy currently applies to:

- `PraxisRuntimeKit`
- `PraxisRuntimeInterface`
- `PraxisFFI`

Internal module refactors may still happen behind these surfaces, but exported payload shapes and integration guidance should follow the rules below.

## Release Buckets

Use three release buckets:

- patch
  Fixes incorrect behavior without changing stable payload shape or public naming.
- minor
  Adds new backward-compatible fields, commands, snapshots, events, or examples.
- major
  Removes, renames, or changes existing stable payload shape or decode behavior.

## Compatibility Rules

Before publishing a release, confirm:

1. every exported schema version still decodes the payloads claimed in `docs/PraxisFFICompatibility.md`
2. new fields are additive and optional for existing consumers unless a major release is intended
3. old versionless payload compatibility remains limited to the currently documented legacy path
4. `README.md`, `CHANGELOG.md`, and migration notes match the shipped contract

## Required Release Artifacts

Each release should update:

- `CHANGELOG.md`
- `README.md`
- `docs/PraxisFFICompatibility.md`
- `docs/PraxisMigrationNotes.md`

If the release touches exported schemas or host integration guidance, also update:

- embedding examples
- architecture / codec tests that assert wire shape
- `docs/PraxisSupportMatrix.md`
- `docs/PraxisHighRiskCapabilitySafety.md`
- `docs/PraxisPerformanceBaseline.md`

## Breaking Change Checklist

Treat the release as breaking if any of the following is true:

- a top-level encoded field is removed or renamed
- a command kind, snapshot kind, or event name is removed or renamed
- a documented legacy decode path is narrowed or removed
- an existing enum raw value changes
- a required field is added to an already released encoded payload shape

## Public Blocking CI Baseline

The public GitHub Actions blocking baseline must stay aligned with `.github/workflows/swift-ci.yml` and README.
Today that defined blocking baseline is macOS-only and consists of:

```bash
swift test
swift run PraxisRuntimeKitRunExample
swift run PraxisRuntimeKitCmpTapExample
swift run PraxisRuntimeKitCapabilitiesExample
swift run PraxisRuntimeKitGovernedExecutionExample
swift run PraxisRuntimeKitSearchExample
swift run PraxisRuntimeKitDurableRuntimeExample
swift run PraxisFFIEmbeddingExample
swift run PraxisAppleHostEmbeddingExample
swift run PraxisExportBaselineExample --iterations 5 --format json
swift run PraxisRuntimeKitSmoke --suite search
swift run PraxisRuntimeKitSmoke --suite cmp-tap
swift run PraxisRuntimeKitSmoke --suite recovery
swift run PraxisRuntimeKitSmoke --suite provisioning
swift run PraxisRuntimeKitSmoke --suite capabilities
swift run PraxisRuntimeKitSmoke --suite code
swift run PraxisRuntimeKitSmoke --suite code-sandbox
swift run PraxisRuntimeKitSmoke --suite code-patch
swift run PraxisRuntimeKitSmoke --suite shell
swift run PraxisRuntimeKitSmoke --suite shell-approval
swift build --product PraxisDemoHostApp
```

This CI baseline is the current public blocking evidence set for the macOS baseline only. It does not imply Linux parity and does not claim native app launch verification.

## Release-Only Additional Verification

Before finalizing a preview or release, also run:

```bash
swift run PraxisRuntimeKitSmoke --suite all
./script/build_and_run.sh --verify
```

Release verification intentionally exceeds public CI coverage. If one of these heavier local checks is skipped, the release note should state which check was skipped and why.
