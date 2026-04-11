# 2026-04-11 CMP Neutral Bootstrap Surface

## Summary

- Added a new host-neutral `bootstrapCmpProject` surface across:
  - `PraxisRuntimeUseCases`
  - `PraxisRuntimeFacades`
  - `PraxisRuntimeInterface`
- Kept the contract independent from `PraxisCLI` and `PraxisAppleUI`.
- Reused existing Swift CMP domain planners instead of inventing a runtime-specific bootstrap model.

## Swift Mapping

- `PraxisCmpGitModel`
  - Reused `PraxisCmpGitPlanner`
  - Reused `PraxisCmpProjectRepoBootstrapPlan`
  - Reused `PraxisCmpGitBranchRuntime`
  - Reused `PraxisCmpGitBackendReceipt`
- `PraxisCmpDbModel`
  - Reused `PraxisCmpDbPlanner`
  - Reused `PraxisCmpDbBootstrapContract`
  - Reused `PraxisCmpDbBootstrapReceipt`
- `PraxisCmpMqModel`
  - Reused `PraxisCmpMqPlanner`
  - Reused `PraxisCmpMqBootstrapReceipt`
  - Reused `PraxisCmpMqTopicBinding`
- `PraxisCmpTypes`
  - Reused `PraxisCmpAgentLineage`
  - Reused `PraxisCmpBranchFamily`

## TS Alignment

- Primary old-TS reference:
  - `src/rax/cmp/project.ts`
- Related bootstrap payload reference:
  - `src/rax/cmp/session.ts`
- Related runtime/project service reference:
  - `src/agent_core/cmp-service/project-service.ts`
  - `src/agent_core/cmp-runtime/infra-bootstrap.ts`

## Boundary

- `bootstrapCmpProject` currently owns:
  - neutral project bootstrap command shape
  - git/db/mq bootstrap receipt assembly
  - lineage topology inference
  - lineage descriptor persistence into the host lineage store when available
- `bootstrapCmpProject` currently does not own:
  - CLI argument parsing
  - GUI-oriented state/view concerns
  - live provider/browser/multimodal behavior
  - a new dedicated CMP runtime state registry

## Current Assumptions

- When callers do not provide `agentIDs`, bootstrap infers them from current projection descriptors and falls back to a single `runtime.local` topology.
- When multiple agents are provided without an explicit hierarchy, bootstrap treats the default agent as the root and the rest as first-level children.
- DB and MQ receipts are currently host-backed planning/readback receipts, not a new heavy execution subsystem.

## Verification

- `swift test`
  - passed
  - `132` tests / `39` suites
