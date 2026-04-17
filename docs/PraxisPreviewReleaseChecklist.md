# Praxis Preview Release Checklist

## Release Intent

Target the first preview only after the outward-facing docs, RuntimeKit examples/smoke paths, export checks, and native demo host all describe the same macOS-first public baseline.

## Public Blocking CI Baseline

The release branch should be green on the public macOS blocking workflow before preview sign-off.
That workflow should cover:

### RuntimeKit examples, export checks, and focused smoke suites

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

This public CI baseline covers the current macOS-first preview baseline, including demo-host build proof, but not native app launch verification.

## Release-Only Additional Verification

Run these heavier local checks before preview sign-off:

```bash
swift run PraxisRuntimeKitSmoke --suite all
./script/build_and_run.sh --verify
```

Use `PraxisRuntimeKitSmoke --suite all` as the aggregate regression sweep and `./script/build_and_run.sh --verify` as native demo-host launch evidence.

## Required Docs

- `README.md`
- `CHANGELOG.md`
- `docs/PraxisPreviewReleaseNote.md`
- `docs/PraxisPositioning.md`
- `docs/PraxisEvaluationChecklist.md`
- `docs/PraxisDemoHost.md`
- `docs/PraxisRepositoryBaseline.md`
- `docs/PraxisFFICompatibility.md`
- `docs/PraxisReleasePolicy.md`
- `docs/PraxisMigrationNotes.md`
- `docs/PraxisSupportMatrix.md`
- `docs/PraxisHighRiskCapabilitySafety.md`
- `docs/PraxisReviewerContextGuide.md`
- `docs/PraxisDurableRuntimeGuide.md`
- `docs/PraxisPerformanceBaseline.md`

## Required Decisions

- preview version string selected
- blocking CI workflow green on the release branch
- Linux placeholder / degraded language reviewed for honesty
- governed execution wording keeps declared contract separate from enforced host behavior where relevant
- durable runtime and reviewer-context wording stays scoped to recovery/readback evidence rather than a general execution-console claim
- native demo host build/run evidence is accepted as the current macOS host baseline, not as a product-shell parity claim
- positioning, evaluation, support, safety, performance, release, and migration materials all tell the same public preview story
