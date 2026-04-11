# 2026-04-11 CMP Review Fixes: Agent Status, Bootstrap Default Agent, Ingest Session Correlation

## Confirmed Findings

- `readbackCmpStatus(projectID:agentID:)` was only querying package descriptors where the scoped agent was the source agent.
- `bootstrapCmpProject()` fell back to `runtime.local` when `agentIDs` was empty, even if `defaultAgentID` was explicitly provided.
- Runtime-interface CMP ingest responses were mapping the generated `requestID` into `sessionID`, which broke session-based correlation.

## Fixes Applied

- Agent-scoped CMP status now merges outbound and inbound package descriptors by querying both `sourceAgentID` and `targetAgentID`.
- Agent-scoped delivery truth readback is now filtered to the scoped package set instead of reusing the whole project-level delivery record set.
- CMP bootstrap now respects `defaultAgentID` before falling back to `runtime.local`.
- CMP ingest now carries the real `sessionID` through `PraxisRuntimeUseCases -> PraxisRuntimeFacades -> PraxisRuntimeInterface`.

## Validation

- Added regression coverage for:
  - receiver-side status readback seeing inbound packages and dispatch state
  - bootstrap with `defaultAgentID` and no explicit agents
  - runtime-interface ingest preserving the caller session ID
- `swift test` passed with `135` tests across `39` suites.
