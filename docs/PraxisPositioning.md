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

## Why The Current Lead Message Is Apple, Swift, Embedding, Governance, Recovery, And Auditability

These are the lead themes because they are where the repository currently has the clearest alignment between implementation, docs, and verification.

- **Apple:** the primary validated host profile is the macOS local baseline, so Apple-hosted runtime evaluation is where the strongest operational truth exists today.
- **Swift:** the public integration story is package-first and Swift-first, with `PraxisRuntimeKit` as the default entry surface for callers.
- **Embedding:** Praxis is most compelling when used as something a host embeds, exports, and negotiates against, rather than as a monolithic standalone shell.
- **Governance:** the repository gives unusual weight to approval boundaries, reviewer context, and risky-capability framing, which is central to how Praxis wants to be trusted.
- **Recovery:** durable state, replay, and readback are part of the shipped story, not an afterthought, and they matter for serious host workflows.
- **Auditability:** support labels, safety notes, and release discipline are treated as product-facing truth, which helps external evaluators separate validated behavior from placeholders or degraded paths.

In short, the current message follows the strongest evidence trail in the repository.

## Why Linux And Broader Cross-Platform Execution Are Not The Lead Message

Linux and broader cross-platform execution are not the lead message because the current repository truth does not justify presenting them as the main commercial story.

Today, Linux is documented as compile-safe placeholder or degraded host truth unless stated otherwise. That is an honest and useful status, but it is not the same as parity with the macOS local baseline. Making cross-platform execution the headline would blur the support matrix and weaken trust in the rest of the positioning.

Praxis is therefore choosing a narrower but more defensible external message:

- lead with the validated Apple and Swift baseline
- lead with embedding-ready exported surfaces
- lead with governance, recovery, and auditability as differentiators
- keep Linux and future broader execution support visible, but secondary, until the support matrix says more

For external evaluators, this is the important takeaway: Praxis is trying to earn trust by being specific about where it is already strong, instead of implying platform breadth that the repository does not yet prove.
