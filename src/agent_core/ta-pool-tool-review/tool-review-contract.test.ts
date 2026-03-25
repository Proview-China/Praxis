import assert from "node:assert/strict";
import test from "node:test";

import {
  createToolReviewGovernanceTrace,
  resolveLifecycleTargetBindingState,
  TA_TOOL_REVIEW_GOVERNANCE_KINDS,
  TA_TOOL_REVIEW_LIFECYCLE_ACTIONS,
} from "./tool-review-contract.js";

test("tool review contract trace helper normalizes the minimal governance envelope", () => {
  const trace = createToolReviewGovernanceTrace({
    actionId: " action-1 ",
    actorId: " reviewer-1 ",
    reason: " stage activation handoff ",
    createdAt: "2026-03-25T08:00:00.000Z",
    request: {
      requestId: "req-1",
      sessionId: "session-1",
      runId: "run-1",
      requestedCapabilityKey: "mcp.playwright",
      requestedTier: "B2",
      mode: "strict",
      canonicalMode: "restricted",
      riskLevel: "risky",
    },
  });

  assert.equal(trace.actionId, "action-1");
  assert.equal(trace.actorId, "reviewer-1");
  assert.equal(trace.reason, "stage activation handoff");
  assert.equal(trace.request?.requestedCapabilityKey, "mcp.playwright");
});

test("tool review contract lifecycle helper maps lifecycle verbs to binding states", () => {
  assert.deepEqual(TA_TOOL_REVIEW_GOVERNANCE_KINDS, [
    "activation",
    "lifecycle",
    "human_gate",
    "replay",
  ]);
  assert.deepEqual(TA_TOOL_REVIEW_LIFECYCLE_ACTIONS, [
    "register",
    "replace",
    "suspend",
    "resume",
    "unregister",
  ]);
  assert.equal(resolveLifecycleTargetBindingState("register"), "active");
  assert.equal(resolveLifecycleTargetBindingState("replace"), "active");
  assert.equal(resolveLifecycleTargetBindingState("resume"), "active");
  assert.equal(resolveLifecycleTargetBindingState("suspend"), "disabled");
  assert.equal(resolveLifecycleTargetBindingState("unregister"), undefined);
});
