# Praxis Positioning

Praxis is a local agent runtime foundation for Swift and Apple-hosted embedding flows. Today it should be evaluated as an integration-oriented runtime package set, not as a finished general-purpose agent product. The default public Swift entry surface is `PraxisRuntimeKit`, while the repository also exposes schema-versioned runtime/export paths for host embedding and boundary negotiation.

This page explains the current external positioning of Praxis in plain terms. For repository truth, platform qualifiers, and release discipline, see [Praxis Platform Status](./PraxisPlatformStatus.md), [Praxis Repository Baseline](./PraxisRepositoryBaseline.md), [Praxis Support Matrix](./PraxisSupportMatrix.md), and [Praxis Release Policy](./PraxisReleasePolicy.md).

## What Praxis Is Today

Praxis today is a Swift + SwiftPM runtime framework for hosts that need an agent runtime they can embed, test, govern, recover, and audit from within an Apple-aligned local environment.

In practical terms, the repository currently centers on:

- a caller-friendly Swift integration surface through `PraxisRuntimeKit`
- embedding-oriented export paths for host negotiation and event transport
- governed capability execution with explicit approval and review boundaries
- durable runtime readback for recovery, replay, and provisioning evidence
- support, safety, and release docs that try to make claimed behavior inspectable

Praxis is strongest when it is treated as infrastructure for a host application or host-side workflow, rather than as an end-user product by itself.

## Who Praxis Is For

Praxis is currently for external evaluators and integration teams who want to answer questions such as:

- Can I embed this runtime into a Swift or Apple-hosted application without inventing the boundary myself?
- Can I review what the runtime claims to support, instead of inferring it from demos or marketing copy?
- Can I keep risky execution behind explicit governance, approval, and audit surfaces?
- Can I recover runtime state and read back what happened after replay, approval, or provisioning flows?

The best fit today is a team that values clear runtime boundaries more than broad platform coverage. If you need a Swift-native integration surface, Apple-hosted embedding, and explicit operational evidence, Praxis is designed to be evaluated on those terms.

## Current Strongest Selling Points

The strongest Praxis story today is not "runs everywhere." It is "gives a host a more governable and inspectable local runtime baseline."

The most concrete strengths are:

- **Swift-native integration surface:** `PraxisRuntimeKit` gives Swift callers a direct, package-first entry point instead of forcing them through a CLI-first architecture.
- **Apple-hosted embedding story:** the current validated baseline is aligned with local macOS execution and Apple-side embedding examples, which makes the host model more concrete than a generic portability claim.
- **Governance:** risky execution paths are framed through explicit capability boundaries, approval state, and reviewer-facing context instead of being presented as unconditional autonomous execution.
- **Recovery:** the runtime emphasizes durable readback, replay, checkpoint, and provisioning evidence, which matters for hosts that need to resume or inspect prior activity.
- **Auditability:** support qualifiers, safety notes, release policy, and exported-surface documentation are part of the product story, so outside evaluators can check what is actually claimed.

If you are comparing Praxis to broader agent stacks, the differentiator is disciplined host integration and evidence-backed runtime behavior, not maximal feature sprawl.

## What Praxis Explicitly Is Not

Praxis is not currently positioned as:

- a mature general-purpose cross-platform agent framework
- a parity-claimed Linux execution stack
- a remote orchestration SaaS
- an all-in-one end-user desktop agent app
- an excuse to treat undocumented behavior as supported behavior

That distinction matters. Praxis is intentionally narrowing the message to the surfaces that are actually documented, exported, and verifiable today.

## Why Praxis Currently Emphasizes Apple, Swift, Embedding, Governance, Recovery, And Auditability

Praxis emphasizes these areas because they are the parts of the system an external evaluator can inspect against the repository today.

The current primary baseline is local macOS operation, and the public integration surface is Swift-first through `PraxisRuntimeKit`. That makes Apple-hosted embedding a concrete evaluation path rather than a hypothetical future direction. If you want to judge whether Praxis fits your host, the repository gives you a direct Swift entry surface, embedding-oriented export paths, and examples that show how a host would negotiate and consume runtime behavior.

The same applies to governance, recovery, and auditability. Praxis does not ask evaluators to assume that risky execution is simply "handled somewhere." The repository documents approval boundaries, reviewer-facing context, durable recovery and replay readback, and release/support qualifiers that describe what is validated and what is not. Those are practical evaluation criteria for teams that care about trust, resumption, and operational evidence.

## Why Linux And Broader Cross-Platform Execution Are Not The Main Story Today

Praxis does not present Linux or broader cross-platform execution as the main story because the current support level is narrower than the macOS local baseline.

Today, Linux is documented as compile-safe placeholder or degraded host truth unless a document says otherwise. For an evaluator, that means Linux support is visible and honestly described, but it should not be read as parity with the primary macOS path. If your adoption decision depends on production-grade cross-platform execution today, the support matrix should be your source of truth.

The practical reading is straightforward:

- evaluate Praxis first as a Swift and Apple-hosted runtime foundation
- treat embedding, governance, recovery, and auditability as the most developed parts of the current story
- read Linux and broader cross-platform execution as partial or future-facing unless the support docs explicitly say more

This tells evaluators where Praxis is ready for serious integration review today, and where stronger platform proof is still needed.
