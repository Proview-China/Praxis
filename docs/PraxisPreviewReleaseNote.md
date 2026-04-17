# Praxis Preview Release Note

This first preview exposes the current Praxis public baseline for Swift and Apple-hosted embedding without pretending that the broader repository is already a fully mature cross-platform agent framework.

The goal of this preview is to make the current public contract reviewable from the outside: what the default Swift integration surface is, what the encoded export boundary looks like today, how the shipped embedding paths are expected to behave, and which verification commands and reference documents define the current baseline.

## What This First Preview Exposes

This preview is intended to expose five things clearly:

- the default Swift integration surface through `PraxisRuntimeKit`
- the current encoded export boundary through `PraxisRuntimeInterface` and `PraxisFFI`
- the first public schema-versioned host-embedding story, including explicit request, response, and event schema version fields
- the shipped executable verification paths that outside evaluators can run without needing internal team context
- the current macOS-first support truth together with honest Linux placeholder or degraded semantics where parity is not yet implemented

In other words, this preview is less about breadth and more about making the current public runtime surfaces inspectable, testable, and documentable.

## Public Surfaces In Scope

The preview scope currently covers these outward-facing surfaces:

- `PraxisRuntimeKit` as the primary Swift integration surface for callers embedding Praxis in a Swift host
- `PraxisRuntimeInterface` as the current versioned encoded request and response contract
- `PraxisFFI` as the bridge-level export surface for host-boundary embedding
- `PraxisFFIEmbeddingExample` as the smallest shipped example of the encoded embedding path
- `PraxisAppleHostEmbeddingExample` as the more host-like Apple embedding flow with architecture negotiation first
- `PraxisExportBaselineExample` as the repeatable export latency, payload-size, and resident-memory baseline path
- `PraxisRuntimeKitSmoke` as the shipped smoke harness for checking the current runtime and capability baseline

These surfaces are the parts of Praxis that this preview expects outside readers and early integrators to evaluate first.

## What This Preview Explicitly Does Not Claim

This preview does not claim any of the following:

- Linux parity with the current macOS local baseline
- unrestricted shell or code execution, PTY support, or streaming-shell parity
- kernel-enforced sandbox isolation merely because `code.sandbox` is publicly inspectable
- identical capability behavior across every host profile
- stable guarantees for undocumented internal module boundaries or experimental payload shapes
- that the repository is already shipping a finalized general-purpose cross-platform UI or host product

Where Linux still relies on compile-safe placeholder or degraded semantics, that reduced truth is the real public status for this preview.
Where a contract is documented but not fully enforced by the host runtime, the contract should be read as a caller-visible declaration rather than as a stronger implementation guarantee.

## Preview Verification Baseline

For this first preview, the documented verification baseline is:

```bash
swift test
swift run PraxisRuntimeKitRunExample
swift run PraxisRuntimeKitCapabilitiesExample
swift run PraxisRuntimeKitSearchExample
swift run PraxisFFIEmbeddingExample
swift run PraxisAppleHostEmbeddingExample
swift run PraxisExportBaselineExample --iterations 5 --format json
swift run PraxisRuntimeKitSmoke --suite all
```

This command set defines the baseline that an outside evaluator should expect to run when checking the current preview story.
It intentionally goes beyond the narrower exported-surface minimum in the release policy so the preview can cover both the export boundary and the current caller-facing RuntimeKit baseline.

## Docs That Define The Current Truth

Use these documents as the source of truth for the current preview:

- support truth: [PraxisSupportMatrix.md](./PraxisSupportMatrix.md)
- safety truth for bounded shell, code, sandbox, and provider-backed high-risk capabilities: [PraxisHighRiskCapabilitySafety.md](./PraxisHighRiskCapabilitySafety.md)
- migration truth for embedding hosts moving onto explicit schema versions: [PraxisMigrationNotes.md](./PraxisMigrationNotes.md)
- compatibility truth for encoded payload shape and decode rules: [PraxisFFICompatibility.md](./PraxisFFICompatibility.md)
- performance and resident-memory baseline truth for the exported path: [PraxisPerformanceBaseline.md](./PraxisPerformanceBaseline.md)
- release discipline and release-bucket rules: [PraxisReleasePolicy.md](./PraxisReleasePolicy.md)
- current repository-facing public baseline summary: [PraxisRepositoryBaseline.md](./PraxisRepositoryBaseline.md)
- shipped change summary for the next release cut: [CHANGELOG.md](../CHANGELOG.md)

When these documents disagree with a higher-level summary, prefer the more specific contract document for that surface.
For example, support labels come from the support matrix, sandbox and approval claims come from the safety note, and export-surface baseline interpretation comes from the performance note.

## Current Reader Guidance

If you are evaluating Praxis from the outside, start with `PraxisRuntimeKit` if you want the default Swift caller path.
Start with `PraxisFFI` and the embedding examples if you are validating host-boundary export behavior.
Read the support matrix before assuming any macOS behavior also exists on Linux, and read the safety note before treating any bounded execution surface as a claim of unrestricted execution.
