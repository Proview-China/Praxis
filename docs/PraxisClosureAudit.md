# Praxis Closure Audit

This document records the Phase 6 close-out audit from the perspective of a first-time external integrator evaluating Praxis. For the first preview cut, the current deliverable is pre-tag release preparation for `v0.1.0-preview.1`, not an already published release.

## Audit Goal

The audit asks one practical question:

Can a new host or SDK integrator understand the exported surface, estimate compatibility risk, run the shipped examples, and find the current platform and safety boundaries without needing internal repository context?

## Current Checklist

- README points to the current recommended entry surface and the current remediation plan.
- Exported schema version rules are documented in one place and match codec behavior.
- Embedding examples cover the smallest bridge path and the host-like negotiation path.
- Release policy, migration notes, support matrix, safety notes, and performance baseline all exist and cross-reference the same exported contract.
- Public blocking CI and Release-Only Additional Verification are aligned across release, support, evaluation, and audit documents.
- Linux is described honestly as placeholder or degraded host truth where parity does not exist.

## Current Status

As of the current Phase 6 baseline, the repository has assembled the current pre-tag preview preparation set below:

- `CHANGELOG.md`
- `docs/PraxisPreviewReleaseNote.md`
- `docs/PraxisPreviewReleaseEvidence.md`
- `PraxisFFIEmbeddingExample`
- `PraxisAppleHostEmbeddingExample`
- `PraxisExportBaselineExample`
- `docs/PraxisPreviewReleaseChecklist.md`
- `docs/PraxisEvaluationChecklist.md`
- `docs/PraxisFFICompatibility.md`
- `docs/PraxisReleasePolicy.md`
- `docs/PraxisMigrationNotes.md`
- `docs/PraxisSupportMatrix.md`
- `docs/PraxisHighRiskCapabilitySafety.md`
- `docs/PraxisPerformanceBaseline.md`

The canonical command and sign-off record now lives in [PraxisPreviewReleaseEvidence.md](./PraxisPreviewReleaseEvidence.md). Any later `docs/releases/v0.1.0-preview.1/` package is follow-up handoff work, not a prerequisite for the current Task 2 evidence record.

## Audit Notes

The current close-out audit intentionally treats the following as non-goals:

- claiming Linux execution parity before a real Linux baseline host exists
- promising provider capability parity across every host profile
- treating declared sandbox contracts as proof of kernel-enforced isolation

## Recommended Repeatable Audit

When re-running a close-out audit later, verify the public blocking CI baseline first:

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

Then run the Release-Only Additional Verification checks:

```bash
swift run PraxisRuntimeKitSmoke --suite all
./script/build_and_run.sh --verify
```

Then manually confirm:

- README, release policy, preview checklist, evaluation checklist, and closure audit describe the same two-tier verification story
- `PraxisPreviewReleaseEvidence.md` remains discoverable from the preview checklist, release policy, and closure audit
- the selected first preview target stays `v0.1.0-preview.1` and is still described as pre-tag and not yet published until a tag exists
- support matrix matches actual claimed platform truth
- release policy and migration notes still match current codec behavior
- schema-version docs still describe missing fields, explicit `null`, and unknown version values correctly
