# Praxis Preview Release Evidence

This document is the canonical release-evidence source for the first Praxis preview preparation lane. It defines what must be verified, what evidence should be retained, and which manual review calls keep the preview story honest before any tag is cut.

## Release Target

- target version: `v0.1.0-preview.1`
- current release state: prepared, not tagged
- publication state: not yet published
- canonical consumers: `docs/PraxisPreviewReleaseChecklist.md`, `docs/PraxisReleasePolicy.md`, and `docs/PraxisClosureAudit.md`

## Scope And Honesty Rules

- This evidence document proves the current repository baseline intended for the first preview. It does not invent new capabilities or upgrade the product story.
- The support truth stays macOS-first. Linux remains placeholder or degraded where `docs/PraxisSupportMatrix.md` says it is.
- The two-tier verification model is required:
  - public blocking CI baseline for the repeatable public proof set
  - Release-Only Additional Verification for the heavier local pre-tag sweep
- `PraxisDemoHostApp` and `./script/build_and_run.sh --verify` are baseline proof that Praxis can run in a native macOS host. They are not evidence of desktop product parity.
- High-risk capability wording must keep declared contracts separate from stronger host-enforced isolation claims.

## Verified Baseline Commands

Use the commands below as the release-preparation baseline for `v0.1.0-preview.1`.
Retain command output, log excerpts, or generated JSON evidence alongside the release-preparation work so later tag approvers can review the same proof set without reinterpreting the policy documents.

### Public Blocking CI Baseline

```bash
swift test
swift run PraxisRuntimeKitRunExample
swift run PraxisRuntimeKitCapabilitiesExample
swift run PraxisRuntimeKitCmpTapExample
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

### Release-Only Additional Verification

```bash
swift run PraxisRuntimeKitSmoke --suite all
./script/build_and_run.sh --verify
```

## Evidence Capture Table

| Command | Purpose | Expected success signal | Artifact or output to retain | Classification |
| --- | --- | --- | --- | --- |
| `swift test` | Validate unit, architecture-guard, and integration-style test coverage for the current SwiftPM baseline. | Test suite exits successfully with no failing cases. | Terminal log or CI excerpt showing the passing test summary. | Public blocking CI |
| `swift run PraxisRuntimeKitRunExample` | Prove the baseline run surface still completes a representative goal path. | Example exits successfully and reports a successful run result. | Terminal log excerpt showing successful completion. | Public blocking CI |
| `swift run PraxisRuntimeKitCapabilitiesExample` | Prove the exported capability catalog and bounded capability lanes are still callable. | Example exits successfully and prints the current capability baseline. | Terminal log excerpt showing capability output. | Public blocking CI |
| `swift run PraxisRuntimeKitCmpTapExample` | Prove CMP/TAP review and approval readback surfaces still produce the documented baseline. | Example exits successfully and reports review or approval evidence without schema drift. | Terminal log excerpt showing CMP/TAP evidence. | Public blocking CI |
| `swift run PraxisRuntimeKitGovernedExecutionExample` | Prove governed execution wording still matches a successful bounded execution sample. | Example exits successfully and reports governed execution evidence. | Terminal log excerpt showing governed execution output. | Public blocking CI |
| `swift run PraxisRuntimeKitSearchExample` | Prove the documented search surface still returns the baseline result shape. | Example exits successfully and reports search output. | Terminal log excerpt showing search results. | Public blocking CI |
| `swift run PraxisRuntimeKitDurableRuntimeExample` | Prove durable checkpoint or readback behavior still works on the current baseline. | Example exits successfully and reports durable runtime evidence. | Terminal log excerpt showing recovery or readback evidence. | Public blocking CI |
| `swift run PraxisFFIEmbeddingExample` | Prove the smallest encoded FFI embedding path still works. | Example exits successfully and reports a successful bridge flow. | Terminal log excerpt showing response and drained event evidence. | Public blocking CI |
| `swift run PraxisAppleHostEmbeddingExample` | Prove the Apple-side host embedding flow still negotiates architecture and completes the baseline request. | Example exits successfully and reports negotiated versions plus successful host-like flow. | Terminal log excerpt showing negotiation and result evidence. | Public blocking CI |
| `swift run PraxisExportBaselineExample --iterations 5 --format json` | Capture the export-surface latency, payload-size, and memory baseline for the current release target. | Command exits successfully and emits valid JSON. | The JSON report artifact and a short note about machine/date context. | Public blocking CI |
| `swift run PraxisRuntimeKitSmoke --suite search` | Exercise the search smoke suite in isolation. | Smoke suite exits successfully. | Terminal log excerpt naming the suite and pass state. | Public blocking CI |
| `swift run PraxisRuntimeKitSmoke --suite cmp-tap` | Exercise the CMP/TAP smoke suite in isolation. | Smoke suite exits successfully. | Terminal log excerpt naming the suite and pass state. | Public blocking CI |
| `swift run PraxisRuntimeKitSmoke --suite recovery` | Exercise the recovery smoke suite in isolation. | Smoke suite exits successfully. | Terminal log excerpt naming the suite and pass state. | Public blocking CI |
| `swift run PraxisRuntimeKitSmoke --suite provisioning` | Exercise the provisioning smoke suite in isolation. | Smoke suite exits successfully. | Terminal log excerpt naming the suite and pass state. | Public blocking CI |
| `swift run PraxisRuntimeKitSmoke --suite capabilities` | Exercise the capabilities smoke suite in isolation. | Smoke suite exits successfully. | Terminal log excerpt naming the suite and pass state. | Public blocking CI |
| `swift run PraxisRuntimeKitSmoke --suite code` | Exercise the bounded code smoke suite in isolation. | Smoke suite exits successfully. | Terminal log excerpt naming the suite and pass state. | Public blocking CI |
| `swift run PraxisRuntimeKitSmoke --suite code-sandbox` | Exercise the declared code-sandbox contract surface. | Smoke suite exits successfully and preserves documented contract wording. | Terminal log excerpt naming the suite and pass state. | Public blocking CI |
| `swift run PraxisRuntimeKitSmoke --suite code-patch` | Exercise the bounded code-patch smoke suite in isolation. | Smoke suite exits successfully. | Terminal log excerpt naming the suite and pass state. | Public blocking CI |
| `swift run PraxisRuntimeKitSmoke --suite shell` | Exercise the bounded shell execution smoke suite in isolation. | Smoke suite exits successfully. | Terminal log excerpt naming the suite and pass state. | Public blocking CI |
| `swift run PraxisRuntimeKitSmoke --suite shell-approval` | Exercise the shell approval/readback smoke suite in isolation. | Smoke suite exits successfully. | Terminal log excerpt naming the suite and pass state. | Public blocking CI |
| `swift build --product PraxisDemoHostApp` | Prove the native macOS demo host still builds from the shipped SwiftPM product. | Build exits successfully and produces the app product. | Terminal build log excerpt. | Public blocking CI |
| `swift run PraxisRuntimeKitSmoke --suite all` | Run the aggregate regression sweep beyond the public blocking subset. | Aggregate smoke suite exits successfully. | Terminal log excerpt showing the full-suite pass summary. | Release-Only Additional Verification |
| `./script/build_and_run.sh --verify` | Prove the native demo host can still be staged and launched as the current macOS baseline host proof. | Script exits successfully and confirms the app launched. | Verification log excerpt and any generated verification note. | Release-Only Additional Verification |

## Manual Review And Sign-Off

Manual sign-off is required even when every command passes. Reviewers should confirm:

- `docs/PraxisSupportMatrix.md` still matches actual platform truth, especially macOS-first support and Linux degraded or placeholder language.
- governed execution wording still separates declared execution contracts from stronger host-enforced isolation claims
- durable runtime wording still describes recovery and readback evidence, not a general execution console
- demo-host language still describes a native macOS baseline proof point rather than cross-platform product parity
- `CHANGELOG.md`, `docs/PraxisPreviewReleaseNote.md`, `docs/PraxisPreviewReleaseChecklist.md`, `docs/PraxisReleasePolicy.md`, `docs/PraxisClosureAudit.md`, and this evidence document all name the same preview target

Sign-off interpretation:

- passing evidence plus manual review means the repository is prepared for a first preview tag review
- passing evidence does not mean a tag already exists
- passing evidence does not mean the preview has been published

## Open Items Before Tagging

- capture real command outputs for the full table above and retain them in the release-preparation handoff
- confirm the release-facing docs still tell the same two-tier verification story after any follow-up edits
- cut the `v0.1.0-preview.1` tag only after this evidence record and the related release-facing docs are reviewed
